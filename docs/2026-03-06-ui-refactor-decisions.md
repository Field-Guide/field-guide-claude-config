# UI Refactor — Brainstorm Decisions

**Date**: 2026-03-06
**Status**: BRAINSTORM COMPLETE — ready for implementation plan

---

## Scope Decision

**Full rewrite** of all 38 screens using a new modular component system.

---

## Design Language: T Vivid

Locked dashboard mockup: "T Premium Elevated — Vivid Variant"

### Core Visual Characteristics
- **Background**: Near-black (#050810)
- **Cards**: Glass effect — very subtle colored background tint + thin colored border + soft box-shadow
- **Colors**: Vivid accent palette — #00E5FF (cyan), #FFC107 (amber), #66BB6A (green), #26C6DA (tracked), #FF7043/#FFA726 (warnings)
- **Typography**: White (#f5f5f5) headers, #ddd body, #555 labels, 8px spaced-letter section headers
- **Borders**: 1px with low opacity color tint (e.g., `rgba(0,229,255,0.1)`)
- **Shadows**: Subtle colored glows (e.g., `box-shadow: 0 2px 24px rgba(0,229,255,0.04)`)
- **Progress bars**: 4px height, gradient fills, rounded
- **Section headers**: 8px, spaced letters, muted color (40-65% opacity)

### Dashboard-Specific Decisions
- Budget card: Hero position, contract value prominent, used/remaining split boxes
- Stats row: 3 items — Entries, Pay Items, Toolbox (removed contractors/locations)
- CTA: "Today's Entry" action card with amber accent
- Approaching Limit: Shows item name, percentage, progress bar, **used/total with units**, remaining
- Top Tracked: Same explicit treatment — percentage + quantities + units
- Weather: Shows current temp + High/Low
- Project number: White/visible (#ccc)
- Drafts: Compact pill below stats

---

## Per-Screen Decisions

### Dashboard
- **Treatment**: Full T Vivid redesign (mockup locked)
- **Structural changes**: Replace 4-stat row (entries/pay items/contractors/toolbox) with 3-stat (entries/pay items/toolbox). Explicit quantities on tracked/limit items.

### Entry Editor (7-section form) — MOCKUP LOCKED: "J Final"
- **Treatment**: Full T Vivid redesign (mockup locked)
- **Layout**: Floating glass section cards, color-coded per section, scrollable
- **Sticky header**: Project name + MM + Entry number (NO temp — already in Basics card)
- **Activities**: Always fully visible — never collapsed or truncated. Full text area with word count + auto-save timestamp
- **Contractors**: Keeps existing tap-to-expand flow — tap a contractor row to expand inline with personnel counters (+/−) and equipment toggle chips. Hit Done to collapse. "Add Contractor" button at bottom. Same interaction as today, T Vivid restyled.
- **Safety section**: 4 fields — Site Safety, SESC, Traffic Control, Visitors on Site
  - **Repeat-last toggle**: Site Safety, SESC, and Traffic Control each get a "Repeat last entry" toggle that prefills from the previous entry (shows source date). Visitors has no toggle (unique per day).
- **Bottom bar**: Save Draft ONLY — no Submit button. Submission happens through the separate review flow. "Auto-saves on edit" hint on left.
- **Section color coding**:
  - Basics: cyan (#00E5FF)
  - Activities: blue (#2196F3)
  - Contractors: amber (#FFC107)
  - Safety: green (#66BB6A)
  - Quantities: teal (#26C6DA)
  - Photos: purple (#BA68C8)
  - Forms: neutral gray

### Home/Calendar Screen
- **Treatment**: T Vivid restyle
- **Structural change**: REMOVE inline editable report from bottom of calendar. Calendar becomes read-only date picker with entry dots. Tap entry → opens full editor. Calendar = visual entries list view.

### List Screens (project list, entries list, drafts, forms, todos, trash, personnel types, admin)
- **Treatment**: T Vivid glass list cards
- **Each list item**: Glass card with subtle border + shadow

### Settings Screen
- **Treatment**: Glass sections with accent lines
- **Each settings group**: Becomes a glass card. Sync status gets vivid treatment. Section headers use accent-line style.

### Project Setup (4 tabs)
- **Treatment**: Keep tabs, restyle with T Vivid
- **No structural changes**: Tab structure works well

### Bottom Sheets & Dialogs (~40 total)
- **Treatment**: Glass sheets with standard handle
- **Standard**: Dark glass background, consistent rounded top corners, standard drag handle widget, SafeArea baked in
- **Dialogs**: Glass card treatment with vivid accent buttons

### Auth Screens (login, register, forgot password, OTP, profile/company setup, pending approval)
- **Treatment**: Light refresh only
- **Already well-tokenized**: Just swap to T Vivid tokens

### Utility Screens (sync dashboard, quantities, calculator, gallery, toolbox home, entry review, review summary, PDF import preview)
- **Treatment**: Restyle + fix structural issues
- **Known issues to fix**: PDF import bottom cutoff, sync dashboard raw colors, gallery fullscreen black/white

---

## Performance Goals
- Fix choppy scrolling everywhere: long lists, mixed content screens, general feel
- Solutions: Lazy-built slivers, const widgets, cached heights, RepaintBoundary, physics tuning, page transitions, animation curves

## Modularity Goals
- Fully tokenized: zero hardcoded colors, dimensions, typography, radius
- Shared component library: all screens built from reusable pieces
- Easy to change: modify tokens → entire app updates

---

## Shared Component Library — LOCKED

**Location**: `lib/core/design_system/`
**Barrel export**: `lib/core/design_system/design_system.dart`

### Atomic Layer
| Component | File | Purpose |
|-----------|------|---------|
| `AppText` | `app_text.dart` | Enforces textTheme slots. `AppText.title('Hello')` replaces inline TextStyle |
| `AppTextField` | `app_text_field.dart` | Glass-styled input with consistent decoration |
| `AppChip` | `app_chip.dart` | Colored chip with variants: `.cyan`, `.amber`, `.green`, `.purple` |
| `AppProgressBar` | `app_progress_bar.dart` | 4px gradient progress bar |
| `AppCounterField` | `app_counter_field.dart` | +/− stepper for personnel counts |
| `AppToggle` | `app_toggle.dart` | Styled toggle with label + subtitle |
| `AppIcon` | `app_icon.dart` | Tokenized icon sizes (small/medium/large/xl) |

### Card Layer
| Component | File | Purpose |
|-----------|------|---------|
| `AppGlassCard` | `app_glass_card.dart` | Core T Vivid card. `accentColor` tints border/bg. Auto shadow. |
| `AppSectionHeader` | `app_section_header.dart` | 8px spaced-letter header + icon + optional count chip |
| `AppListTile` | `app_list_tile.dart` | Glass-styled list row |
| `AppPhotoGrid` | `app_photo_grid.dart` | Photo thumbnail grid with add button |

### Surface Layer
| Component | File | Purpose |
|-----------|------|---------|
| `AppScaffold` | `app_scaffold.dart` | Wraps Scaffold + SafeArea + bottom padding + T Vivid bg gradient |
| `AppBottomBar` | `app_bottom_bar.dart` | Sticky bottom action bar with blur backdrop |
| `AppBottomSheet` | `app_bottom_sheet.dart` | Glass sheet + drag handle + SafeArea |
| `AppDialog` | `app_dialog.dart` | Glass dialog + vivid accent buttons |
| `AppStickyHeader` | `app_sticky_header.dart` | Blur-backdrop sticky context header |

### Composite Layer
| Component | File | Purpose |
|-----------|------|---------|
| `AppEmptyState` | `app_empty_state.dart` | Icon + title + subtitle + optional CTA |
| `AppErrorState` | `app_error_state.dart` | Error state with retry button |
| `AppLoadingState` | `app_loading_state.dart` | Centered spinner with optional label |
| `AppBudgetWarningChip` | `app_budget_warning_chip.dart` | Budget discrepancy chip (dashboard + quantities) |
| `AppDragHandle` | `app_drag_handle.dart` | Standard sheet drag handle bar |

---

## Implementation Phasing

**Branch**: New branch off main (created at implementation start)
**Approach**: Foundation first, then screens. Logical commits per phase.

### Phase 1: Foundation — Theme + Design System Components
- Update `AppTheme` with missing tokens (17 gaps from audit)
- Re-export `space12`, `space16`, all animation curves
- Add `radiusXSmall`, icon size tokens, `statusNeutral`, warning chip colors
- Build all Atomic layer components
- Build all Card layer components
- Build all Surface layer components
- Build all Composite layer components
- **Commit**: `feat(design-system): add T Vivid component library`

### Phase 2: Dashboard Rewrite
- Rewrite `ProjectDashboardScreen` using locked T Vivid mockup
- Replace `DashboardStatCard`, `BudgetOverviewCard`, `TrackedItemRow`, `AlertItemRow` with design system components
- Add explicit quantities to tracked/approaching-limit items
- Replace 4-stat row with 3-stat (Entries, Pay Items, Toolbox)
- Weather shows current + H/L
- **Commit**: `feat(dashboard): rewrite with T Vivid design system`

### Phase 3: Entry Editor Rewrite
- Rewrite `EntryEditorScreen` using locked J Final mockup
- Color-coded floating glass section cards
- Activities always fully visible
- Safety: add repeat-last toggles (Site Safety, SESC, Traffic Control)
- Safety: ensure Visitors field is present
- Contractors: restyle existing tap-to-expand flow with T Vivid
- Bottom bar: Save Draft only (no Submit)
- Sticky context header (project + entry number)
- **Commit**: `feat(entry-editor): rewrite with T Vivid design system`

### Phase 4: Calendar/Home Screen
- Remove inline editable report from bottom
- Calendar = read-only date picker with entry dots
- Tap date shows entry list, tap entry opens editor
- T Vivid restyle
- **Commit**: `feat(calendar): simplify to read-only view with T Vivid`

### Phase 5: List Screens Batch
- ProjectListScreen, EntriesListScreen, DraftsListScreen, FormsListScreen, TodosScreen, TrashScreen, PersonnelTypesScreen, AdminDashboardScreen
- All get glass list cards
- **Commit**: `feat(lists): rewrite all list screens with glass cards`

### Phase 6: Settings + Sync Screens
- SettingsScreen: glass sections with accent lines
- SyncDashboardScreen: replace all raw Colors with tokens
- SyncStatusIcon: tokenize
- ConflictViewerScreen, ProjectSelectionScreen: restyle
- **Commit**: `feat(settings): rewrite settings and sync screens`

### Phase 7: Project Setup + Quantities
- ProjectSetupScreen: keep tabs, T Vivid restyle
- QuantitiesScreen, QuantityCalculatorScreen: restyle + fix budget chip duplication
- **Commit**: `feat(projects): restyle setup and quantities screens`

### Phase 8: Utility Screens
- Gallery (fix fullscreen black/white), Toolbox, Calculator
- PDF Import Preview (fix bottom cutoff)
- Entry Review, Review Summary
- **Commit**: `feat(utility): restyle remaining utility screens`

### Phase 9: Auth Screens — Light Refresh
- Swap to T Vivid tokens (colors, spacing, typography)
- No structural changes
- **Commit**: `feat(auth): light refresh with T Vivid tokens`

### Phase 10: Bottom Sheets + Dialogs
- Migrate all ~40 modal surfaces to AppBottomSheet / AppDialog
- Consistent drag handle, SafeArea, glass styling
- **Commit**: `feat(modals): standardize all sheets and dialogs`

### Phase 11: Performance Pass
- Add RepaintBoundary to list items and heavy widgets
- Lazy-build slivers for long lists
- Tune scroll physics and overscroll effects
- Page transition animations with tokenized curves
- Profile and fix any remaining jank
- **Commit**: `perf: scroll smoothing, lazy slivers, repaint boundaries`

### Phase 12: Cleanup
- Delete unused old widgets
- Remove any remaining hardcoded values
- Run full `flutter analyze` — zero issues
- Final code review
- **Commit**: `chore: remove old widgets and remaining hardcoded values`

---

## Separate Plans
- **Sync auth fix**: `.claude/plans/2026-03-06-sync-auth-fix.md` (ready to implement independently)

## Reference Documents
- **UI refactor reference**: `.claude/docs/ui-refactor-reference-2026-03-06.md` (700+ violations inventory)
- **Theme token audit**: `.claude/docs/ui-audit-theme-tokens-2026-03-06.md`
- **Dependency map**: `.claude/plans/ui-dependency-map.md`
