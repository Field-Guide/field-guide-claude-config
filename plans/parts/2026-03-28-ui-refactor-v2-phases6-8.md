# Phases 6-8: Feature Screen Rewrites

> **Dependency**: All phases depend on Phase 1 (design system tokens + components).
> Phases 6, 7, and 8 are independent of each other and Phases 2-5 — they can run in parallel.

---

## Phase 6: Settings + Sync Screens

**Goal**: Migrate the settings/sync screens cluster to the design system. SyncDashboardScreen and ConflictViewerScreen are the two worst offenders in the entire codebase — nearly every color is hardcoded.

### Sub-phase 6.A: SettingsScreen

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.A.1: Replace AppTheme color tokens

The SettingsScreen has moderate violations — mostly `AppTheme.*` static references that need to become theme-aware.

**Instance list** (line numbers from source):

| Line | Old | New | WHY |
|------|-----|-----|-----|
| 165 | `color: AppTheme.primaryCyan` | `color: cs.primary` | Icon tint |
| 174 | `color: AppTheme.primaryCyan` | `color: cs.primary` | Admin icon tint |
| 182 | `color: AppTheme.statusError` | `color: cs.error` | Sign out icon |
| 222 | `color: AppTheme.statusWarning` | `color: fg.statusWarning` | Trash badge bg |
| 228 | `color: Colors.white` | `color: fg.textInverse` | Trash badge text |
| 245 | `color: AppTheme.statusWarning` | `color: fg.statusWarning` | Clear cache icon |
| 261 | `backgroundColor: AppTheme.success` | `backgroundColor: fg.statusSuccess` | Template chip |

**Pattern** — for every `AppTheme.primaryCyan` icon tint:
```dart
// WHY: Migrate from static AppTheme to theme-aware tokens
// BEFORE
leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryCyan),
// AFTER
leading: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
```

#### Step 6.A.2: Replace hardcoded EdgeInsets

| Line | Old | New |
|------|-----|-----|
| 219 | `EdgeInsets.symmetric(horizontal: 8, vertical: 2)` | `EdgeInsets.symmetric(horizontal: AppTheme.space2, vertical: 2)` |
| 346 | `SizedBox(height: 32)` | `SizedBox(height: AppTheme.space8)` |

#### Step 6.A.3: Replace hardcoded TextStyle

| Line | Old | New |
|------|-----|-----|
| 228-230 | `TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)` | `TextStyle(color: fg.textInverse, fontSize: 12, fontWeight: FontWeight.bold)` |

---

### Sub-phase 6.B: SyncDashboardScreen (WORST OFFENDER)

**Files:**
- Modify: `lib/features/sync/presentation/screens/sync_dashboard_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

> NOTE: This file has 15+ direct `Colors.*` usages and multiple hardcoded paddings. Every instance is listed below.

#### Step 6.B.1: Add theme accessor locals to build methods

Every method that uses colors needs these locals at the top:

```dart
// WHY: Single declaration avoids repeated Theme.of(context) lookups
final cs = Theme.of(context).colorScheme;
final fg = FieldGuideColors.of(context);
```

Add to: `build()`, `_buildSummaryCard()`, `_buildStatChip()` (needs context param), `_buildPendingBucketsSection()` (needs context param), `_buildIntegrityCard()` (needs context param), `_buildSectionHeader()` (needs context param).

NOTE: `_buildStatChip`, `_buildSectionHeader`, `_buildPendingBucketsSection`, and `_buildIntegrityCard` currently have no `BuildContext` parameter. Add one, and update call sites.

#### Step 6.B.2: Replace Colors.* in _buildSummaryCard (lines 148-210)

**Full instance list:**

| Line | Old | New | Context |
|------|-----|-----|---------|
| 171 | `Colors.red` | `cs.error` | Sync failure icon color |
| 173 | `Colors.amber` | `fg.accentAmber` | Syncing icon color |
| 174 | `Colors.green` | `fg.statusSuccess` | All-synced icon color |

**Pattern:**
```dart
// WHY: Hardcoded status colors break in dark mode
// BEFORE
color: syncProvider.hasPersistentSyncFailure
    ? Colors.red
    : syncProvider.isSyncing
        ? Colors.amber
        : Colors.green,
// AFTER
color: syncProvider.hasPersistentSyncFailure
    ? cs.error
    : syncProvider.isSyncing
        ? fg.accentAmber
        : fg.statusSuccess,
```

#### Step 6.B.3: Replace Colors.* in _buildStatChip (lines 212-221)

| Line | Old | New |
|------|-----|-----|
| 217 | `TextStyle(fontSize: 20, fontWeight: FontWeight.bold)` | `tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)` |
| 219 | `TextStyle(fontSize: 12, color: Colors.grey)` | `tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)` |

**Pattern:**
```dart
// BEFORE
Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
// AFTER
Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
```

#### Step 6.B.4: Replace Colors.* in _buildSectionHeader (lines 275-283)

| Line | Old | New |
|------|-----|-----|
| 278-280 | `TextStyle(fontSize: 16, fontWeight: FontWeight.w600)` | `tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)` |

#### Step 6.B.5: Replace tokens in _buildPendingBucketsSection (lines 286-391)

| Line | Old | New | Context |
|------|-----|-----|---------|
| 313 | `AppTheme.primaryCyan` | `cs.primary` | Active bucket icon |
| 313 | `AppTheme.textTertiary` | `fg.textTertiary` | Inactive bucket icon |
| 319 | `AppTheme.textTertiary` | `fg.textTertiary` | Inactive bucket text |
| 326 | `Colors.white` | `fg.textInverse` | Active chip text |
| 326 | `AppTheme.textTertiary` | `fg.textTertiary` | Inactive chip text |
| 330-331 | `AppTheme.statusWarning` | `fg.statusWarning` | Active chip bg |
| 331 | `AppTheme.surfaceElevated` | `fg.surfaceElevated` | Inactive chip bg |
| 349-350 | `AppTheme.textTertiary` | `fg.textTertiary` | Breakdown text (2 instances) |
| 356 | `AppTheme.textTertiary` | `fg.textTertiary` | Breakdown trailing text |
| 377 | `AppTheme.textTertiary` | `fg.textTertiary` | Other bucket icon |
| 383 | `AppTheme.statusWarning` | `fg.statusWarning` | Other chip bg |

**Pattern** — chip background:
```dart
// WHY: AppTheme.statusWarning is a compile-time constant that ignores theme mode
// BEFORE
backgroundColor: total > 0
    ? AppTheme.statusWarning
    : AppTheme.surfaceElevated,
// AFTER
backgroundColor: total > 0
    ? fg.statusWarning
    : fg.surfaceElevated,
```

#### Step 6.B.6: Replace Colors.* in _buildIntegrityCard (lines 393-420)

| Line | Old | New | Context |
|------|-----|-----|---------|
| 405 | `Colors.orange` | `fg.accentOrange` | Drift warning icon |
| 405 | `Colors.green` | `fg.statusSuccess` | OK icon |
| 416 | `TextStyle(fontSize: 11, color: Colors.grey)` | `tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)` | Timestamp text |

**Pattern:**
```dart
// BEFORE
color: driftDetected ? Colors.orange : Colors.green,
// AFTER
color: driftDetected ? fg.accentOrange : fg.statusSuccess,
```

#### Step 6.B.7: Replace Colors.orange in MaterialBanner (line 111)

| Line | Old | New |
|------|-----|-----|
| 111 | `color: Colors.orange` | `color: fg.accentOrange` |

#### Step 6.B.8: Replace hardcoded padding

| Line | Old | New |
|------|-----|-----|
| 126 | `EdgeInsets.all(16)` | `EdgeInsets.all(AppTheme.space4)` |
| 129 | `SizedBox(height: 16)` | `SizedBox(height: AppTheme.space4)` |
| 131 | `SizedBox(height: 16)` | `SizedBox(height: AppTheme.space4)` |
| 136 | `SizedBox(height: 8)` | `SizedBox(height: AppTheme.space2)` |
| 157 | `EdgeInsets.all(16)` | `EdgeInsets.all(AppTheme.space4)` |
| 177 | `SizedBox(width: 12)` | `SizedBox(width: AppTheme.space3)` |
| 299 | `SizedBox(height: 8)` | `SizedBox(height: AppTheme.space2)` |
| 343 | `EdgeInsets.only(left: 56, right: 16)` | `EdgeInsets.only(left: 56, right: AppTheme.space4)` |

---

### Sub-phase 6.C: SyncStatusIcon

**Files:**
- Modify: `lib/features/sync/presentation/widgets/sync_status_icon.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.C.1: Replace hardcoded Colors.*

All 3 color usages are in `_getColor()` method:

| Line | Old | New |
|------|-----|-----|
| 34 | `Colors.red` | `Theme.of(context).colorScheme.error` |
| 35 | `Colors.amber` | `FieldGuideColors.of(context).accentAmber` |
| 36 | `Colors.green` | `FieldGuideColors.of(context).statusSuccess` |

NOTE: `_getColor` currently takes `SyncProvider`. It needs `BuildContext` too, or the caller must pass the resolved colors. Recommended: change signature to `_getColor(BuildContext context, SyncProvider provider)` and update the call in `build()`.

**Pattern:**
```dart
// BEFORE
Color _getColor(SyncProvider provider) {
  if (provider.hasPersistentSyncFailure) return Colors.red;
  if (provider.isSyncing || provider.hasPendingChanges) return Colors.amber;
  return Colors.green;
}
// AFTER
Color _getColor(BuildContext context, SyncProvider provider) {
  final cs = Theme.of(context).colorScheme;
  final fg = FieldGuideColors.of(context);
  if (provider.hasPersistentSyncFailure) return cs.error;
  if (provider.isSyncing || provider.hasPendingChanges) return fg.accentAmber;
  return fg.statusSuccess;
}
```

---

### Sub-phase 6.D: ConflictViewerScreen (WORST OFFENDER)

**Files:**
- Modify: `lib/features/sync/presentation/screens/conflict_viewer_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

> NOTE: This file has zero AppTheme usage (except one `AppTheme.statusError` for snackbar). Almost everything is raw `Colors.*`.

#### Step 6.D.1: Add theme accessors

Add to `build()` and `_buildConflictCard()`:
```dart
final cs = Theme.of(context).colorScheme;
final fg = FieldGuideColors.of(context);
final tt = Theme.of(context).textTheme;
```

`_buildConflictCard` needs `BuildContext` parameter added (currently uses `context` from class state — refactor to pass explicitly for clarity).

#### Step 6.D.2: Replace empty-state Colors.green (line 190)

```dart
// BEFORE
Icon(Icons.check_circle, size: 48, color: Colors.green),
// AFTER
Icon(Icons.check_circle, size: 48, color: fg.statusSuccess),
```

#### Step 6.D.3: Replace Colors.* in _buildConflictCard (lines 209-316)

**Full instance list:**

| Line | Old | New | Context |
|------|-----|-----|---------|
| 235 | `Colors.orange` | `fg.accentOrange` | Warning icon in ListTile leading |
| 238 | `TextStyle(fontWeight: FontWeight.w600)` | `tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)` | Table name text |
| 263 | `TextStyle(fontSize: 12, color: Colors.grey)` | `tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)` | Record ID text |
| 269-272 | `TextStyle(fontSize: 13, fontWeight: FontWeight.w600)` | `tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)` | "Lost Data:" label |
| 280 | `Colors.grey.shade100` | `fg.surfaceElevated` | Code block background |
| 284-287 | `TextStyle(fontSize: 11, fontFamily: 'monospace')` | `tt.bodySmall?.copyWith(fontFamily: 'monospace')` | JSON text |

**Pattern** — code block container:
```dart
// WHY: Colors.grey.shade100 is invisible on dark backgrounds
// BEFORE
decoration: BoxDecoration(
  color: Colors.grey.shade100,
  borderRadius: BorderRadius.circular(4),
),
// AFTER
decoration: BoxDecoration(
  color: fg.surfaceElevated,
  borderRadius: BorderRadius.circular(4),
),
```

#### Step 6.D.4: Replace hardcoded padding

| Line | Old | New |
|------|-----|-----|
| 199 | `EdgeInsets.all(16)` | `EdgeInsets.all(AppTheme.space4)` |
| 231 | `EdgeInsets.only(bottom: 8)` | `EdgeInsets.only(bottom: AppTheme.space2)` |
| 258 | `EdgeInsets.symmetric(horizontal: 16)` | `EdgeInsets.symmetric(horizontal: AppTheme.space4)` |
| 265 | `SizedBox(height: 8)` | `SizedBox(height: AppTheme.space2)` |
| 275 | `SizedBox(height: 4)` | `SizedBox(height: AppTheme.space1)` |
| 278 | `EdgeInsets.all(8)` | `EdgeInsets.all(AppTheme.space2)` |
| 292 | `SizedBox(height: 12)` | `SizedBox(height: AppTheme.space3)` |
| 300 | `SizedBox(width: 8)` | `SizedBox(width: AppTheme.space2)` |
| 308 | `SizedBox(height: 8)` | `SizedBox(height: AppTheme.space2)` |
| 191 | `SizedBox(height: 12)` | `SizedBox(height: AppTheme.space3)` |

---

### Sub-phase 6.E: ProjectSwitcher

**Files:**
- Modify: `lib/features/projects/presentation/widgets/project_switcher.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.E.1: Replace AppTheme and Colors.* references

| Line | Old | New | Context |
|------|-----|-----|---------|
| 43 | `AppTheme.primaryCyan` | `cs.primary` | Folder icon in app bar chip |
| 134 | `Colors.grey[300]` | `cs.outlineVariant` | Drag handle |
| 207 | `AppTheme.primaryCyan` | `cs.primary` | Add icon |
| 210 | `AppTheme.primaryCyan` | `cs.primary` | "+ New Project" text |
| 231 | `AppTheme.primaryCyan` | `cs.primary` | Selected radio icon |
| 231 | `Colors.grey` | `cs.onSurfaceVariant` | Unselected radio icon |

**Pattern** — drag handle:
```dart
// WHY: Colors.grey[300] is a hardcoded shade; use outline variant for theme support
// BEFORE
color: Colors.grey[300],
// AFTER
color: cs.outlineVariant,
```

#### Step 6.E.2: Replace hardcoded padding

| Line | Old | New |
|------|-----|-----|
| 28 | `EdgeInsets.symmetric(horizontal: 8, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppTheme.space2, vertical: AppTheme.space1)` |

---

### Sub-phase 6.F: MemberDetailSheet

**Files:**
- Modify: `lib/features/settings/presentation/widgets/member_detail_sheet.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.F.1: Replace AppTheme and Colors.* references

| Line | Old | New | Context |
|------|-----|-----|---------|
| 54 | `Colors.grey[300]` | `cs.outlineVariant` | Drag handle |
| 65 | `AppTheme.primaryCyan.withValues(alpha: 0.2)` | `cs.primary.withValues(alpha: 0.2)` | Avatar bg |
| 69 | `AppTheme.primaryCyan` | `cs.primary` | Avatar text |
| 92 | `AppTheme.statusError` | `cs.error` | Deactivated status text |
| 194 | `AppTheme.success` | `fg.statusSuccess` | Reactivate icon (2 instances: icon + label) |
| 195-209 | `AppTheme.statusError` | `cs.error` | Deactivate icon/label/border (3 instances) |
| 229 | `Colors.grey` | `cs.onSurfaceVariant` | Info row icon color |
| 244 | `AppTheme.success` | `fg.statusSuccess` | Sync health "Active" badge |
| 247 | `Colors.grey` | `cs.onSurfaceVariant` | Sync health "Never" badge |

#### Step 6.F.2: Replace hardcoded padding

| Line | Old | New |
|------|-----|-----|
| 38-41 | `EdgeInsets.only(left: 16, right: 16, top: 16, ...)` | `EdgeInsets.only(left: AppTheme.space4, right: AppTheme.space4, top: AppTheme.space4, ...)` |
| 52 | `EdgeInsets.only(bottom: 16)` | `EdgeInsets.only(bottom: AppTheme.space4)` |
| 142 | `EdgeInsets.symmetric(horizontal: 12, vertical: 8)` | `EdgeInsets.symmetric(horizontal: AppTheme.space3, vertical: AppTheme.space2)` |
| 251 | `EdgeInsets.symmetric(horizontal: 8, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppTheme.space2, vertical: AppTheme.space1)` |

---

### Sub-phase 6.G: ScaffoldWithNavBar

**Files:**
- Modify: `lib/core/router/app_router.dart` (only the `ScaffoldWithNavBar` class, lines 648-834)

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.G.1: Replace Colors.* in ScaffoldWithNavBar

**Full instance list:**

| Line | Old | New | Context |
|------|-----|-----|---------|
| 680 | `Colors.red.shade700` | `cs.error` | Sync error snackbar background |
| 684 | `Colors.white` | `cs.onError` | Snackbar action text color |
| 720 | `Colors.orange` | `fg.accentOrange` | Stale sync warning icon |
| 743 | `Colors.orange` | `fg.accentOrange` | Offline banner leading icon |
| 744 | `Colors.orange.shade50` | `fg.accentOrange.withValues(alpha: 0.08)` | Offline banner bg |

**Pattern** — snackbar:
```dart
// WHY: Colors.red.shade700 breaks dark mode, cs.error adapts to theme
// BEFORE
backgroundColor: Colors.red.shade700,
...
textColor: Colors.white,
// AFTER
backgroundColor: cs.error,
...
textColor: cs.onError,
```

**Pattern** — offline banner background:
```dart
// WHY: Colors.orange.shade50 is a Material 2 constant; use derived opacity for theme support
// BEFORE
backgroundColor: Colors.orange.shade50,
// AFTER
backgroundColor: fg.accentOrange.withValues(alpha: 0.08),
```

NOTE: ScaffoldWithNavBar is a StatelessWidget, so add locals at top of `build()`:
```dart
final cs = Theme.of(context).colorScheme;
final fg = FieldGuideColors.of(context);
```

The snackbar callback closure captures context — the `cs`/`fg` resolved inside it should use the `context` parameter passed to the callback, not the outer build context. Resolve this by inlining Theme lookup inside the closure.

---

### Sub-phase 6.H: Settings Widgets

**Files:**
- Modify: `lib/features/settings/presentation/widgets/sync_section.dart`
- Modify: `lib/features/settings/presentation/widgets/section_header.dart`
- Modify: `lib/features/settings/presentation/widgets/theme_section.dart`
- Modify: `lib/features/settings/presentation/widgets/sign_out_dialog.dart`
- Modify: `lib/features/settings/presentation/widgets/clear_cache_dialog.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 6.H.1: SyncSection token migration

| Line | Old | New |
|------|-----|-----|
| 32 | `AppTheme.success` | `fg.statusSuccess` |
| 33 | `AppTheme.primaryBlue` | `cs.primary` |
| 35 | `AppTheme.success` | `fg.statusSuccess` |
| 37 | `AppTheme.statusError` | `cs.error` |
| 39 | `AppTheme.textTertiary` | `fg.textTertiary` |
| 41 | `AppTheme.statusWarning` | `fg.statusWarning` |
| 94 | `AppTheme.statusWarning` | `fg.statusWarning` |
| 94 | `AppTheme.textTertiary` | `fg.textTertiary` |
| 99 | `AppTheme.textTertiary` | `fg.textTertiary` |
| 158 | `AppTheme.statusWarning` | `fg.statusWarning` |
| 165 | `AppTheme.statusError` | `cs.error` |

NOTE: SyncSection is a StatelessWidget. `_getSyncColor` and `_buildBucketSummary` need `BuildContext` parameter added. The `build` method already has context — pass it through.

#### Step 6.H.2: Audit other settings widgets

SectionHeader, ThemeSection, SignOutDialog, ClearCacheDialog — read each and replace any `AppTheme.*` or `Colors.*`. These files are likely cleaner. Do a sweep and fix any instances found.

---

### Sub-phase 6.I: Quality Gate

**Agent**: `qa-testing-agent`

#### Step 6.I.1: Static analysis

```
pwsh -Command "flutter analyze lib/features/settings/ lib/features/sync/presentation/ lib/core/router/app_router.dart lib/features/projects/presentation/widgets/project_switcher.dart"
```

#### Step 6.I.2: Verify zero remaining violations

Search all modified files for `Colors\.` regex — must return zero hits (except `Colors.transparent` which is acceptable).

Search all modified files for `AppTheme\.primaryCyan`, `AppTheme\.textPrimary`, `AppTheme\.textSecondary`, `AppTheme\.textTertiary`, `AppTheme\.success`, `AppTheme\.surfaceElevated`, `AppTheme\.surfaceDark`, `AppTheme\.surfaceHighlight` — must return zero hits.

#### Step 6.I.3: Run sync-related tests

```
pwsh -Command "flutter test test/features/sync/"
```

---

## Phase 7: Project Setup + Quantities

**Goal**: Migrate the project management and quantities screens. ProjectSetupScreen has 9 EdgeInsets violations; QuantitiesScreen has 3 hardcoded `Colors.*` in the budget warning chip.

### Sub-phase 7.A: QuantitiesScreen

**Files:**
- Modify: `lib/features/quantities/presentation/screens/quantities_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 7.A.1: Replace Colors.* in budget warning chip (lines 172-180)

| Line | Old | New | Context |
|------|-----|-----|---------|
| 173 | `Colors.orange.shade800` | `fg.accentOrange` | Warning icon color |
| 178 | `Colors.amber.shade50` | `fg.accentAmber.withValues(alpha: 0.1)` | Chip background |
| 179 | `Colors.amber.shade200` | `fg.accentAmber.withValues(alpha: 0.4)` | Chip border |

**Pattern:**
```dart
// WHY: Material shade constants don't adapt to dark mode
// BEFORE
Chip(
  avatar: Icon(Icons.warning_amber_rounded,
      color: Colors.orange.shade800, size: 18),
  label: const Text(
    'Unit price discrepancy detected — using bid amounts',
    style: TextStyle(fontSize: 12),
  ),
  backgroundColor: Colors.amber.shade50,
  side: BorderSide(color: Colors.amber.shade200),
),
// AFTER
Chip(
  avatar: Icon(Icons.warning_amber_rounded,
      color: fg.accentOrange, size: 18),
  label: const Text(
    'Unit price discrepancy detected — using bid amounts',
    style: TextStyle(fontSize: 12),
  ),
  backgroundColor: fg.accentAmber.withValues(alpha: 0.1),
  side: BorderSide(color: fg.accentAmber.withValues(alpha: 0.4)),
),
```

NOTE: Consider replacing this entire Chip with `AppBudgetWarningChip` from the design system (Phase 1). If that component exists, use it directly instead of inline styling.

#### Step 7.A.2: Replace remaining AppTheme static colors

| Line | Old | New |
|------|-----|-----|
| 185 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 208-209 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 215-216 | `AppTheme.textTertiary` | `fg.textTertiary` |
| 274 | `AppTheme.error` (in `_buildErrorState` of GalleryScreen — skip, wrong file) | — |

---

### Sub-phase 7.B: ProjectSetupScreen

**Files:**
- Modify: `lib/features/projects/presentation/screens/project_setup_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 7.B.1: Replace hardcoded EdgeInsets

The ProjectSetupScreen is a large file (500+ lines). Scan for all `EdgeInsets` and `SizedBox` usages that use raw numbers instead of `AppTheme.space*` tokens.

**Search pattern**: `EdgeInsets\.(all|symmetric|only)\([^A]` — any EdgeInsets not starting with AppTheme.

**Known violations** (9 reported in inventory):
Replace all hardcoded `EdgeInsets.all(16)` with `EdgeInsets.all(AppTheme.space4)`, `EdgeInsets.all(8)` with `EdgeInsets.all(AppTheme.space2)`, etc.

**Mapping reference:**
| Value | Token |
|-------|-------|
| 4 | `AppTheme.space1` |
| 8 | `AppTheme.space2` |
| 12 | `AppTheme.space3` |
| 16 | `AppTheme.space4` |
| 20 | `AppTheme.space5` |
| 24 | `AppTheme.space6` |
| 32 | `AppTheme.space8` |

#### Step 7.B.2: Replace any AppTheme.* static color references

Scan for `AppTheme.primaryCyan`, `AppTheme.textSecondary`, `AppTheme.textTertiary`, `AppTheme.statusError`, `AppTheme.success`, `Colors.*` and replace per the color mapping table.

---

### Sub-phase 7.C: Project Setup Widgets

**Files:**
- Modify: `lib/features/projects/presentation/widgets/project_details_form.dart`
- Modify: `lib/features/projects/presentation/widgets/contractor_editor_widget.dart` (if it exists here — may be in entries)
- Modify: `lib/features/projects/presentation/widgets/assignments_step.dart`
- Modify: `lib/features/projects/presentation/widgets/add_location_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/add_contractor_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/add_equipment_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/bid_item_dialog.dart`
- Modify: `lib/features/projects/presentation/widgets/pay_item_source_dialog.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 7.C.1: Sweep each widget for violations

For each widget file, search for `Colors\.`, `AppTheme\.`, hardcoded `EdgeInsets`, hardcoded `TextStyle(fontSize:`, hardcoded `BorderRadius`. Replace using the standard mapping tables.

---

### Sub-phase 7.D: Quantity Widgets

**Files:**
- Modify: `lib/features/quantities/presentation/widgets/quantity_summary_header.dart`
- Modify: `lib/features/quantities/presentation/widgets/bid_item_card.dart`
- Modify: `lib/features/quantities/presentation/widgets/bid_item_detail_sheet.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 7.D.1: Sweep each widget for violations

Same approach as 7.C.1. These widgets were not flagged as worst offenders, so violations should be minor.

---

### Sub-phase 7.E: QuantityCalculatorScreen

**Files:**
- Modify: `lib/features/quantities/presentation/screens/quantity_calculator_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 7.E.1: Light sweep

Inventory notes this screen has clean AppTheme usage. Verify and fix any remaining `Colors.*` or hardcoded padding.

---

### Sub-phase 7.F: Quality Gate

**Agent**: `qa-testing-agent`

#### Step 7.F.1: Static analysis

```
pwsh -Command "flutter analyze lib/features/quantities/ lib/features/projects/"
```

#### Step 7.F.2: Verify zero remaining violations

Search all modified files for `Colors\.` regex (except `Colors.transparent`).

#### Step 7.F.3: Run related tests

```
pwsh -Command "flutter test test/features/projects/ test/features/quantities/"
```

---

## Phase 8: Utility Screens

**Goal**: Migrate the remaining utility screens — gallery, PDF import, entry review, forms hub, toolbox, and calculator. The gallery photo viewer is the standout worst offender.

### Sub-phase 8.A: GalleryScreen + _PhotoViewerScreen

**Files:**
- Modify: `lib/features/gallery/presentation/screens/gallery_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 8.A.1: Replace AppTheme static colors in GalleryScreen (lines 1-513)

The main GalleryScreen body uses `AppTheme.*` but not raw `Colors.*`. Replace:

| Line | Old | New |
|------|-----|-----|
| 185 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 233 | `AppTheme.textTertiary` | `fg.textTertiary` |
| 240 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 249 | `AppTheme.textTertiary` | `fg.textTertiary` |
| 274 | `AppTheme.error` | `cs.error` |
| 283 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 391 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 426 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |

#### Step 8.A.2: Replace ALL Colors.* in _PhotoViewerScreen (lines 517-641) — WORST OFFENDER

This is a full-screen photo viewer with black background and white text. Every color is hardcoded.

**Full instance list:**

| Line | Old | New | Context |
|------|-----|-----|---------|
| 549 | `Colors.black` | `cs.scrim` | Scaffold background |
| 551 | `Colors.black` | `cs.scrim` | AppBar background |
| 552 | `Colors.white` | `cs.onScrim` | AppBar foreground |
| 555 | `TextStyle(color: Colors.white)` | Redundant — remove (foregroundColor handles it) | AppBar title |
| 580 | `Colors.white54` | `cs.onScrim.withValues(alpha: 0.54)` | Broken image icon |
| 593 | `Colors.black87` | `cs.scrim.withValues(alpha: 0.87)` | Info container bg |
| 600-604 | `TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)` | `tt.titleMedium?.copyWith(color: cs.onScrim)` | Caption text |
| 609 | `TextStyle(color: Colors.white70, fontSize: 12)` | `tt.bodySmall?.copyWith(color: cs.onScrim.withValues(alpha: 0.7))` | Timestamp |
| 615 | `TextStyle(color: Colors.white70, fontSize: 14)` | `tt.bodyMedium?.copyWith(color: cs.onScrim.withValues(alpha: 0.7))` | Notes |
| 623 | `Colors.white54` | `cs.onScrim.withValues(alpha: 0.54)` | Attribution text |

**Pattern** — full-screen dark viewer:
```dart
// WHY: Photo viewer needs intentionally dark background regardless of theme.
// Using cs.scrim (dark in both modes) instead of Colors.black gives us
// semantic naming while preserving the dark viewer experience.
// BEFORE
return Scaffold(
  backgroundColor: Colors.black,
  appBar: AppBar(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    title: Text(
      '${_currentIndex + 1} / ${widget.photos.length}',
      style: const TextStyle(color: Colors.white),
    ),
  ),
// AFTER
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;
return Scaffold(
  backgroundColor: cs.scrim,
  appBar: AppBar(
    backgroundColor: cs.scrim,
    foregroundColor: cs.onScrim,
    title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
  ),
```

NOTE: The `style: const TextStyle(color: Colors.white)` on the title at line 555 is redundant when `foregroundColor` is set. Remove it entirely.

**Pattern** — info container:
```dart
// BEFORE
color: Colors.black87,
// AFTER
color: cs.scrim.withValues(alpha: 0.87),
```

#### Step 8.A.3: PhotoThumbnail widget

**Files:**
- Modify: `lib/features/photos/presentation/widgets/photo_thumbnail.dart`

Scan for `Colors.*` and `AppTheme.*` violations. Replace per standard mapping.

---

### Sub-phase 8.B: PDF Import Screens

**Files:**
- Modify: `lib/features/pdf/presentation/screens/pdf_import_preview_screen.dart`
- Modify: `lib/features/pdf/presentation/screens/mp_import_preview_screen.dart`
- Modify: `lib/features/pdf/presentation/widgets/extraction_banner.dart`
- Modify: `lib/features/pdf/presentation/widgets/extraction_detail_sheet.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 8.B.1: Sweep each file for violations

These screens were not flagged as worst offenders. Scan for `Colors\.`, `AppTheme\.` static colors, hardcoded `EdgeInsets`, and replace per standard mapping tables.

---

### Sub-phase 8.C: Entry Review Screens

**Files:**
- Modify: `lib/features/entries/presentation/screens/entry_review_screen.dart`
- Modify: `lib/features/entries/presentation/screens/review_summary_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 8.C.1: ReviewSummaryScreen violations

| Line | Old | New | Context |
|------|-----|-----|---------|
| 93 | `Colors.red` | `cs.error` | Failed submit snackbar bg |
| 170 | `Colors.black.withValues(alpha: 0.1)` | `fg.shadowLight` | Bottom bar shadow |
| 189 | `Colors.white` | `cs.onPrimary` | Spinner in FilledButton |
| 233 | `AppTheme.textPrimary` | `cs.onSurface` | Summary header count text |
| 239 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` | "X skipped" text |
| 299 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` | Location subtitle |
| 309 | `AppTheme.statusSuccess` | `fg.statusSuccess` | "READY" label (2 instances) |
| 310 | `AppTheme.textTertiary` | `fg.textTertiary` | "SKIPPED" label (2 instances) |

**Pattern** — shadow:
```dart
// WHY: Colors.black.withValues breaks in light themes with white surfaces
// BEFORE
color: Colors.black.withValues(alpha: 0.1),
// AFTER
color: fg.shadowLight,
```

#### Step 8.C.2: EntryReviewScreen sweep

Scan for `Colors.*` and `AppTheme.*` violations. Replace per mapping.

---

### Sub-phase 8.D: Forms Hub Widgets

**Files:**
- Modify: `lib/features/forms/presentation/screens/mdot_hub_screen.dart`
- Modify: `lib/features/forms/presentation/screens/form_viewer_screen.dart`
- Modify: `lib/features/forms/presentation/widgets/hub_proctor_content.dart`
- Modify: `lib/features/forms/presentation/widgets/form_accordion.dart`
- Modify: `lib/features/forms/presentation/widgets/status_pill_bar.dart`
- Modify: `lib/features/forms/presentation/widgets/summary_tiles.dart`
- Modify: `lib/features/forms/presentation/widgets/hub_header_content.dart`
- Modify: `lib/features/forms/presentation/widgets/hub_quick_test_content.dart`
- Modify: `lib/features/forms/presentation/widgets/form_thumbnail.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 8.D.1: HubProctorContent — heavy violations (14 TextStyle, 7 EdgeInsets, 6 BorderRadius)

This widget is the densest violator in Phase 8. It uses `AppTheme.*` static tokens extensively. All need migration to runtime theme lookups.

**AppTheme static color instances in HubProctorContent:**

| Line | Old | New |
|------|-----|-----|
| 83 | `AppTheme.surfaceDark` | `cs.surface` |
| 102 | `AppTheme.statusSuccess.withValues(alpha: 0.08)` | `fg.statusSuccess.withValues(alpha: 0.08)` |
| 103 | `AppTheme.surfaceHighlight` | `cs.outline` |
| 107 | `AppTheme.statusSuccess.withValues(alpha: 0.35)` | `fg.statusSuccess.withValues(alpha: 0.35)` |
| 108 | `AppTheme.surfaceBright` | `cs.outlineVariant` |
| 141 | `AppTheme.statusSuccess` | `fg.statusSuccess` |
| 142 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 148-150 | `AppTheme.textInverse` | `fg.textInverse` |
| 160 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |
| 235 | `AppTheme.statusSuccess` | `fg.statusSuccess` |
| 264 | `AppTheme.statusSuccess.withValues(alpha: 0.06)` | `fg.statusSuccess.withValues(alpha: 0.06)` |
| 266 | `AppTheme.statusSuccess.withValues(alpha: 0.35)` | `fg.statusSuccess.withValues(alpha: 0.35)` |
| 319 | `AppTheme.statusWarning` | `fg.statusWarning` |
| 360 | `AppTheme.accentAmber` | `fg.accentAmber` |
| 361 | `AppTheme.textInverse` | `fg.textInverse` |
| 403-407 | `AppTheme.statusSuccess`, `AppTheme.statusWarning`, `AppTheme.surfaceBright` | `fg.statusSuccess`, `fg.statusWarning`, `cs.outlineVariant` |
| 419 | `AppTheme.surfaceHighlight` | `cs.outline` |
| 436 | `AppTheme.textSecondary.withValues(alpha: 0.4)` | `cs.onSurfaceVariant.withValues(alpha: 0.4)` |
| 459-461 | `AppTheme.statusSuccess`, `AppTheme.statusWarning` | `fg.statusSuccess`, `fg.statusWarning` |
| 479 | `AppTheme.textSecondary` | `cs.onSurfaceVariant` |

NOTE: HubProctorContent is a StatelessWidget. Add theme accessors at top of `build()`:
```dart
final cs = Theme.of(context).colorScheme;
final fg = FieldGuideColors.of(context);
final tt = Theme.of(context).textTheme;
```

All `const TextStyle(...)` and `const TextStyle(color: AppTheme.*)` must lose the `const` keyword since theme tokens are runtime values.

#### Step 8.D.2: Hardcoded TextStyle instances in HubProctorContent

Replace all hardcoded `fontSize` + `fontWeight` combinations with text theme references:

| Pattern | Old | New |
|---------|-----|-----|
| Section labels | `TextStyle(fontSize: 12, fontWeight: FontWeight.w800)` | `tt.labelSmall?.copyWith(fontWeight: FontWeight.w800)` |
| Live card title | `TextStyle(fontSize: 15, fontWeight: FontWeight.w800)` | `tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)` |
| Calc pair label | `TextStyle(fontSize: 11, color: AppTheme.textSecondary)` | `tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)` |
| Calc pair value | `TextStyle(fontWeight: FontWeight.w800)` | `tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800)` |
| Weight card text | `TextStyle(fontSize: 15, fontWeight: FontWeight.w700)` | `tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)` |
| Delta text | `TextStyle(fontSize: 10, fontWeight: FontWeight.w800)` | `tt.labelSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 10)` |
| LIVE badge | `TextStyle(color: AppTheme.textInverse, fontSize: 10, fontWeight: FontWeight.w800)` | `tt.labelSmall?.copyWith(color: fg.textInverse, fontWeight: FontWeight.w800, fontSize: 10)` |

#### Step 8.D.3: Hardcoded EdgeInsets in HubProctorContent

| Line | Old | New |
|------|-----|-----|
| 81 | `EdgeInsets.all(10)` | `EdgeInsets.all(AppTheme.space3)` |
| 99 | `EdgeInsets.all(12)` | `EdgeInsets.all(AppTheme.space3)` |
| 135-137 | `EdgeInsets.symmetric(horizontal: 8, vertical: 4)` | `EdgeInsets.symmetric(horizontal: AppTheme.space2, vertical: AppTheme.space1)` |
| 262 | `EdgeInsets.all(12)` | `EdgeInsets.all(AppTheme.space3)` |
| 325 | `EdgeInsets.symmetric(horizontal: 8)` | `EdgeInsets.symmetric(horizontal: AppTheme.space2)` |
| 385-386 | `EdgeInsets.symmetric(horizontal: 12, vertical: 14)` | `EdgeInsets.symmetric(horizontal: AppTheme.space3, vertical: 14)` |
| 439-440 | `EdgeInsets.symmetric(horizontal: 4, vertical: 10)` | `EdgeInsets.symmetric(horizontal: AppTheme.space1, vertical: AppTheme.space3)` |

#### Step 8.D.4: Hardcoded BorderRadius in HubProctorContent

| Line | Old | New |
|------|-----|-----|
| 84 | `BorderRadius.circular(10)` | `BorderRadius.circular(AppTheme.space3)` |
| 104 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppTheme.space3)` |
| 143 | `BorderRadius.circular(999)` | `BorderRadius.circular(999)` — keep (pill shape, intentional) |
| 265 | `BorderRadius.circular(10)` | `BorderRadius.circular(AppTheme.space3)` |
| 362 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppTheme.space3)` |
| 417 | `BorderRadius.circular(10)` | `BorderRadius.circular(AppTheme.space3)` |

#### Step 8.D.5: Sweep remaining hub widgets

For FormAccordion, StatusPillBar, SummaryTiles, HubHeaderContent, HubQuickTestContent, FormThumbnail — scan each for `Colors.*`, `AppTheme.*` static colors, hardcoded `EdgeInsets`, `TextStyle`, `BorderRadius`. Replace per mapping tables.

---

### Sub-phase 8.E: Toolbox + Calculator

**Files:**
- Modify: `lib/features/toolbox/presentation/screens/toolbox_home_screen.dart`
- Modify: `lib/features/calculator/presentation/screens/calculator_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 8.E.1: Light sweep

Both screens are flagged as clean in the inventory. Verify no violations remain. Fix any stragglers.

---

### Sub-phase 8.F: EditProfileScreen

**Files:**
- Modify: `lib/features/settings/presentation/screens/edit_profile_screen.dart`

**Agent**: `frontend-flutter-specialist-agent`

#### Step 8.F.1: Light sweep

Flagged as clean. Verify no violations remain.

---

### Sub-phase 8.G: Quality Gate

**Agent**: `qa-testing-agent`

#### Step 8.G.1: Static analysis

```
pwsh -Command "flutter analyze lib/features/gallery/ lib/features/pdf/presentation/ lib/features/entries/presentation/screens/entry_review_screen.dart lib/features/entries/presentation/screens/review_summary_screen.dart lib/features/forms/ lib/features/toolbox/ lib/features/calculator/ lib/features/settings/presentation/screens/edit_profile_screen.dart lib/features/photos/presentation/widgets/"
```

#### Step 8.G.2: Verify zero remaining violations

Global sweep of all Phase 8 files:
- `Colors\.` regex (except `Colors.transparent`) — must be zero
- `AppTheme\.primaryCyan`, `AppTheme\.textPrimary`, `AppTheme\.textSecondary`, `AppTheme\.textTertiary`, `AppTheme\.success`, `AppTheme\.surfaceElevated`, `AppTheme\.surfaceDark`, `AppTheme\.surfaceHighlight`, `AppTheme\.statusError`, `AppTheme\.statusSuccess`, `AppTheme\.statusWarning`, `AppTheme\.accentAmber`, `AppTheme\.textInverse`, `AppTheme\.error`, `AppTheme\.primaryBlue`, `AppTheme\.surfaceBright` — must be zero

#### Step 8.G.3: Run related tests

```
pwsh -Command "flutter test test/features/gallery/ test/features/pdf/ test/features/entries/ test/features/forms/"
```

#### Step 8.G.4: Visual smoke test

Build debug APK and verify the following screens render correctly in both light and dark mode:
1. Settings screen (all sections visible)
2. Sync Dashboard (summary card, pending buckets, integrity cards)
3. Conflict Viewer (empty state with green check)
4. Gallery (photo grid + filter sheet)
5. Gallery photo viewer (dark background, white text, broken image placeholder)
6. Quantities screen (budget warning chip)
7. Forms hub (proctor content with live card, weight cards, calc card)
8. Review summary (ready/skipped entries, submit button)
