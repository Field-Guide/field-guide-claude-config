# Design System Overhaul Spec

**Date:** 2026-04-06
**Status:** Approved
**Scope:** Full bottom-up UI layer refactor — tokens, theme, responsive layout, performance, screen decomposition, component library, lint enforcement

---

## 1. Overview

### Purpose

Overhaul the app's design system and UI layer to be fully tokenized, responsive across phone/tablet/desktop, and performant. Currently the app suffers from ~400 magic number violations, a 1,777-line monolithic theme file, 10+ screens over 600 lines, general sluggishness, and layout overflow errors across screen sizes.

### Scope

- **A: Design system infrastructure** — tokens, theme, components, folder structure
- **B: Full UI layer** — screens, feature widgets, shared widgets, router surfaces, dialogs/sheets, decomposition, tokenization, performance, responsive layout
- High-contrast theme removal (unused)
- 11 UI-related GitHub issues fixed inline
- New lint rules for ongoing enforcement
- Documentation, testing, HTTP driver, and logging updates

### Success Criteria

- [ ] Zero hardcoded `Colors.*`, `BorderRadius.circular(N)`, `EdgeInsets.*(N)`, or `TextStyle(` in presentation layer
- [ ] `app_theme.dart` reduced from 1,777 lines to <400 via data-driven builder (2 themes: dark + light)
- [ ] All design system tokens accessible via `ThemeExtension.of(context)` with `standard`, `compact`, and `comfortable` density variants
- [ ] Density is selected automatically in the live app from breakpoint/screen context; no user-facing density toggle in Settings
- [ ] Responsive breakpoint system with canonical layout patterns (phone/tablet/desktop)
- [ ] No UI-facing screen, widget, controller, mixin, state/helper, or driver-facing screen-contract file exceeds 300 lines; priority oversized files decomposed first, then remaining UI files brought under threshold
- [ ] No extracted helper, build method, or orchestration method is allowed to become a hidden god object; 300 lines is the absolute ceiling, with materially smaller focused units expected in practice
- [ ] Every sync-relevant screen exposes a stable verification contract through `TestingKeys`, `screen_registry.dart`, `flow_registry.dart`, and driver diagnostics so `SyncCoordinator`/sync verification flows can drive and observe it without widget-tree archaeology
- [ ] All 11 UI-related GitHub issues closed
- [ ] Widgetbook catalog covering all design system components + key feature widgets
- [ ] Flutter DevTools profiling shows no frame budget violations (>16ms) on key screens
- [ ] Atomic Design folder structure for design system (~56 components across tokens/atoms/molecules/organisms/surfaces/feedback/layout/animation)
- [ ] Desktop hover states + focus indicators on all interactive components
- [ ] 10 new lint rules enforced at error severity in CI
- [ ] `flutter analyze` and `dart run custom_lint` both pass cleanly at the end of the overhaul, and no new `ignore`, `ignore_for_file`, analyzer exclusions, rule downgrades, allowlists, or other suppression tricks are introduced to get there
- [ ] All `.claude/` architecture documentation updated
- [ ] HTTP driver and logging updated for new component structure

### Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Token architecture | ThemeExtension-only | Supports density switching, animated lerp, multi-form-factor targets |
| Responsive layout | Breakpoints + canonical patterns | Breakpoints provide primitives, canonical patterns prevent reinvention per screen |
| Screen decomposition | Extract + promote + fix issues inline | Touch each file once, fix issues alongside refactor |
| Widgetbook depth | Design system + key feature widgets | Covers reusable components, feature widgets added incrementally |
| Migration strategy | Tokenize during decomposition | Avoids touching files twice |
| Density control | Automatic in the live app; Widgetbook/dev knobs only | Keeps runtime UX consistent while still allowing design review and QA coverage |
| Platform priority | Phone first, tablet strong, desktop decent | Matches actual product priority while still producing a coherent multi-form-factor system |
| Split-pane usage | Selective on tablet/desktop | Use only where it materially improves workflow instead of forcing every screen into a desktop pattern |
| Desktop input | Hover + focus indicators | 80% of desktop feel, minimal investment |
| Performance approach | Profile first, then systematic pass | Catches non-obvious bottlenecks before broad optimization |
| Animation style | Material 3 motion + selective premium polish | Matches existing Material foundation, upgrades key surfaces |
| Lint rollout | Rules first (P0), warn during refactor, error at end | Creates violation inventory that guides all subsequent work |
| Sync verification surface | Stable screen contracts via keys + driver registries + diagnostics | Sync verification must survive decomposition without widget-tree archaeology |
| Decomposition guardrail | No UI god objects over 300 lines, including extracted helpers | Prevents fake decomposition where complexity is merely moved sideways |

### Approaches Rejected

| Approach | Why Rejected |
|----------|-------------|
| Static tokens (DesignConstants only) | Can't switch density at runtime, no animated theme transitions, spacing won't adapt across phone/tablet/desktop |
| Hybrid tokens (ThemeExtension for some, static for others) | Inconsistent pattern, loses density switching, would need re-refactor later |
| Big-bang token migration | High risk — too many files changing at once, hard to review |
| Feature-by-feature migration | Touches files twice (once for tokenization, once for decomposition) |
| Widgetbook full storybook | Too much upfront investment for cataloging full screens |
| Desktop shortcuts + context menus | Desktop is lowest priority, can be added later |

---

## 2. Token System

### New ThemeExtensions (5)

| Extension | Fields | Variants |
|-----------|--------|----------|
| `FieldGuideSpacing` | `xs`(4), `sm`(8), `md`(16), `lg`(24), `xl`(32), `xxl`(48) | `standard`, `compact`, `comfortable` |
| `FieldGuideRadii` | `xs`(4), `sm`(8), `compact`(10), `md`(12), `lg`(16), `xl`(24), `full`(999) | `standard` (single variant — radii don't change per density) |
| `FieldGuideMotion` | `fast`(150ms), `normal`(300ms), `slow`(500ms), `pageTransition`(350ms), `curveStandard`, `curveDecelerate`, `curveEmphasized` | `standard`, `reduced` (accessibility — durations go to zero) |
| `FieldGuideShadows` | `none`, `low`, `medium`, `high`, `modal` — each a `List<BoxShadow>` | `standard`, `flat` (no shadows for low-end devices) |
| `FieldGuideColors` | Already exists with 16 fields — expand to absorb remaining `AppColors` semantic colors that vary per theme | `dark`, `light` (remove HC) |

### Migration Mapping

| Current | Target |
|---------|--------|
| `DesignConstants.space4` | `FieldGuideSpacing.of(context).md` |
| `DesignConstants.radiusMedium` | `FieldGuideRadii.of(context).md` |
| `DesignConstants.animationNormal` | `FieldGuideMotion.of(context).normal` |
| `DesignConstants.elevationMedium` | `FieldGuideShadows.of(context).medium` |
| `AppColors.statusSuccess` | Stays in `AppColors` (same across all themes) |
| `AppColors.surfaceElevated` | Absorbed into `FieldGuideColors` (varies per theme) |
| `AppColors.hc*` constants | Deleted (HC theme removed) |
| `AppTheme.darkTheme` / `lightTheme` | Data-driven builder using token sets |
| `AppTheme.highContrastTheme` | Deleted |
| `AppTheme` deprecated color re-exports | Deleted |

### Density Variant Mapping

| Context | Spacing Variant | Usage |
|---------|----------------|-------|
| Phone portrait | `compact` | Tight screens, maximize content |
| Phone landscape | `standard` | Slightly more breathing room |
| Tablet | `standard` | Balanced layout |
| Desktop | `comfortable` | Generous whitespace |
| Data-dense screens (pay apps, quantities) | `compact` override | Fits more rows |

### Density Control Policy

- Density is automatic in the live app; no Settings toggle is added for end users
- Widgetbook exposes density knobs for design review, QA, and regression testing
- Screen-level overrides are allowed for intentionally dense workflows (pay apps, quantities, some form editors)

### Static Fallback

`DesignConstants` keeps its role as the static fallback for contexts without `BuildContext` (golden test setup, domain layer references). All widget code migrates to ThemeExtension accessors.

---

## 3. Responsive Layout System

### Breakpoints

| Name | Width | Target |
|------|-------|--------|
| `compact` | 0–599 | Phone portrait |
| `medium` | 600–839 | Phone landscape, small tablet |
| `expanded` | 840–1199 | Tablet, small desktop window |
| `large` | 1200+ | Desktop, large tablet landscape |

Aligned with Material 3 canonical breakpoint names.

### New Layout Widgets (`design_system/layout/`)

| Widget | Purpose |
|--------|---------|
| `AppBreakpoint` | Static utility — `AppBreakpoint.of(context)` returns current breakpoint enum. Single source of truth. |
| `AppResponsiveBuilder` | Builder widget providing current breakpoint. Screens use this to switch layout structure. |
| `AppAdaptiveLayout` | Canonical layout container — takes `body`, optional `detail` pane, optional `sidePanel`. Auto-switches single-column / two-pane / three-region. |
| `AppResponsivePadding` | Screen-appropriate horizontal margins. Phone=16px, tablet=24px, desktop=32px+. Reads from spacing tokens. |
| `AppResponsiveGrid` | Column grid adapting count per breakpoint. Phone=1-2 cols, tablet=2-3, desktop=3-4. |

### Canonical Layout Mapping

| Screen | Phone | Tablet | Desktop |
|--------|-------|--------|---------|
| Home / Calendar | Single column calendar + preview stack | Calendar/list + preview pane | Same as tablet, wider |
| Dashboard | Single column, scrollable cards | Two-column grid | Three-column with side panel |
| Entry Editor | Single column, tabbed sections | Body + detail pane | Same as tablet, wider |
| Project List | Single column list | List-detail | List-detail, wider |
| Project Setup | Single column wizard / section switcher (not top tabs) | Left section nav + content, wider fields, 2-col groups | Same as tablet, wider |
| Entries List | Single column list | List-detail | List-detail, wider |
| Form Editor (Hub) | Single column, accordion sections | Two-pane: section nav left, content right | Same as tablet, wider |
| Forms List | Single column | Two-column | Same as tablet |
| Quantities | Single column list | List + calculator side-by-side | Same as tablet |
| Settings | Single column | Left nav + content | Same as tablet |
| Todos | Single column | Two-column | Same as tablet |
| Calculator | Single column | Wider input + results side-by-side | Same as tablet |

Only the screens that materially benefit from split panes adopt them. Split views are not a blanket requirement for every large-screen surface.

### Navigation Adaptation

| Breakpoint | Navigation |
|------------|------------|
| `compact` | Bottom navigation (current shell pattern) |
| `medium` | `NavigationRail` (collapsed, icons only) |
| `expanded` / `large` | `NavigationRail` (expanded, icons + labels) |

Navigation adaptation applies to the root app shell. Feature-level split panes are separate canonical patterns, not a requirement to mirror shell navigation everywhere.

### UI Screen Contract For Sync Verification

Every screen that can trigger, block, visualize, or verify sync-sensitive work must expose a stable verification surface that survives refactors. "Easy to expose" means the screen can be instantiated, navigated to, and driven through named contracts rather than ad hoc widget-tree inspection.

| Contract Surface | Requirement | Why |
|------------------|-------------|-----|
| `TestingKeys` | Each sync-relevant screen keeps a root sentinel key plus stable action/state keys for create/edit/save/delete/sync/export flows | Sync verification agents need durable selectors after decomposition |
| `screen_registry.dart` | Every decomposed screen shell and promoted child screen remains constructible through the screen registry with required seed arguments documented | Harness runs and coordinator/orchestrator verification need isolated screen bootstrapping |
| `flow_registry.dart` | Navigation flows must be updated whenever routes/screens move so verification flows still express intended journeys declaratively | Sync flows must not depend on stale route assumptions |
| Driver diagnostics | Driver must expose current route plus the active screen contract metadata needed by verification (`breakpoint`, `density`, `theme`, `motion`, screen id/root key) | Coordinators/orchestrators need observable UI state, not screenshot guessing |
| Screen orchestration boundary | Screen shells may orchestrate view state, but sync operations must stay behind typed provider/coordinator/query-service APIs and be surfaced through stable UI contracts | Prevents direct engine reach-through while keeping sync verification practical |

Screens explicitly treated as sync-relevant in this overhaul include sync dashboard/conflict surfaces plus any decomposed entry, project, forms, quantities, toolbox, and settings screens whose UI state participates in sync verification, export verification, enrollment/removal, or change-log-triggering workflows.

### Form Editor Components (extracted from 0582B for future reuse)

| Component | Extracted From | Purpose |
|-----------|---------------|---------|
| `AppFormSection` | `form_accordion.dart` + hub build | Collapsible section with status indicator, icon, title |
| `AppFormSectionNav` | Hub section tab/pill nav | Section navigator with completion status. Sidebar (tablet) or pills (phone). |
| `AppFormStatusBar` | `status_pill_bar.dart` | Form-level completion status, validation summary |
| `AppFormFieldGroup` | Hub field layout patterns | Groups related fields with label, help text, responsive columns |
| `AppFormSummaryTile` | `summary_tiles.dart` | Compact read-only display of completed field value |
| `AppFormThumbnail` | `form_thumbnail.dart` | Mini preview card for form selection |

### MdotHubScreen Decomposition Target

From (1,198 lines, 37 methods in one State class, 5 screen classes in one file):
```
screens/
├── mdot_hub_screen.dart (~300 lines — shell + state + orchestration)
├── form_fill_screen.dart
├── quick_test_entry_screen.dart
├── proctor_entry_screen.dart
├── weights_entry_screen.dart
└── form_pdf_preview_screen.dart
widgets/
├── hub_header_content.dart (keep, 119 lines)
├── hub_proctor_content.dart (decompose from 486 → ~250 + extracted field groups)
├── hub_quick_test_content.dart (keep, 239 lines)
├── hub_section_navigator.dart (NEW)
├── hub_status_summary.dart (NEW)
└── hub_field_groups/ (NEW — domain-specific field clusters)
```

Form-specific content stays in `features/forms/`. Generic form editor primitives go into `design_system/organisms/`.

### Component Discovery Gate

Before each screen decomposition batch:
1. Grep for private `_*Card`, `_*Tile`, `_*Row`, `_*Badge`, `_*Banner`, `_*Dialog`, `_*Sheet` classes
2. Cross-reference against design system barrel — if pattern appears in 2+ features, promote
3. Check for raw Flutter widgets that should be wrapped
4. Log discoveries in running inventory, promote before decomposing screens that use them

This gate runs at the start of every implementation batch, not just once.

---

## 4. State Management, Performance & Lint Enforcement

### Provider Rebuild Optimization

| Current Pattern | Problem | Target Pattern |
|----------------|---------|---------------|
| `Consumer<Provider>` wrapping large subtrees | Entire subtree rebuilds | `Selector<Provider, T>` for surgical rebuilds |
| `context.watch<Provider>()` in build | Full rebuild | `context.select((p) => p.field)` |
| `notifyListeners()` on every setter | Fires when value unchanged | Guard: `if (value == _value) return;` |

### Sliver Migration Targets

| Screen | Current | Target |
|--------|---------|--------|
| Entries list | `ListView.builder` | `CustomScrollView` + `SliverList.builder` |
| Project list | Mixed Column/ListView | `CustomScrollView` with sliver sections |
| Quantities | `ListView` | `CustomScrollView` + `SliverList.builder` |
| Todos | Nested lists | `CustomScrollView` + grouped slivers |
| Dashboard | `SingleChildScrollView` + `Column` | `CustomScrollView` + mixed slivers |
| Forms list | `ListView` | `CustomScrollView` + `SliverList.builder` |

`ProjectListScreen` and `ProjectDashboardScreen` already contain partial sliver work. Scope here is to standardize, finish, and verify those patterns rather than re-migrate them from scratch.

### RepaintBoundary Placement

| Location | Why |
|----------|-----|
| Each item in scrolling lists | Isolate per-row repaints |
| `AppBottomBar` | Persists while content scrolls |
| `AppGlassCard` with `BackdropFilter` | Blur is expensive |
| Widgets using `AnimationController` | Isolate animated from static |
| `ScaffoldWithNavBar` body vs navigation | Navigation static during scroll |

### Profiling Protocol

1. Run Flutter DevTools timeline on 5 worst screens (entry editor, project setup, home, project list, mdot hub)
2. Capture frame render times — identify >16ms frames
3. Widget Rebuild tracker to find rebuild storms
4. Fix top 5 bottlenecks surgically
5. Systematic pattern pass (slivers, Selector, RepaintBoundary)
6. Re-profile to verify improvement

### New Custom Lint Rules (10)

| Rule | Severity | Catches |
|------|----------|---------|
| `no_raw_button` | warning → error | `ElevatedButton(`, `TextButton(`, `OutlinedButton(`, `IconButton(` — use `AppButton.*` |
| `no_raw_divider` | warning → error | `Divider(` — use `AppDivider` |
| `no_raw_tooltip` | warning → error | `Tooltip(` — use `AppTooltip` |
| `no_raw_dropdown` | warning → error | `DropdownButton(`, `DropdownButtonFormField(` — use `AppDropdown` |
| `no_raw_snackbar` | warning → error | `ScaffoldMessenger.of(context).showSnackBar(` — use `SnackBarHelper`/`AppSnackbar` |
| `no_hardcoded_spacing` | warning → error | `EdgeInsets.all(N)`, `SizedBox(width: N)` with literal — use spacing tokens |
| `no_hardcoded_radius` | warning → error | `BorderRadius.circular(N)` with literal — use `FieldGuideRadii.of(context).*` |
| `no_hardcoded_duration` | warning → error | `Duration(milliseconds: N)` in presentation — use `FieldGuideMotion.of(context).*` |
| `no_raw_navigator` | info | `Navigator.push(`, `Navigator.pop(` — use GoRouter |
| `prefer_design_system_banner` | warning → error | Feature banners should compose `AppBanner` |

Rules apply across presentation screens, presentation widgets, `shared/widgets/`, and router-owned UI surfaces. Allowlist remains `design_system/` itself because components may wrap raw Flutter widgets internally.

Lint rules start as warnings (P0), flip to errors at end of refactor (P6).

### Existing Lint Rules (unchanged)

`no_hardcoded_colors`, `no_inline_text_style`, `no_raw_scaffold`, `no_raw_dialog`, `no_raw_bottom_sheet`, `no_silent_catch` — already enforced.

### Structural Guardrails

- The 300-line ceiling is a hard architecture rule for UI-facing screen files, extracted widget files, presentation controllers/mixins/helpers, and driver-facing screen contract helpers that exist only to support the UI layer
- Extracting a 600-line screen into a 280-line shell plus a 500-line helper/mixin does not satisfy this spec
- Long private `_build*` methods, giant helper functions, and oversized "utils" files count as decomposition failures even if the parent screen file falls under 300 lines
- If an extracted artifact still trends large, split by responsibility immediately (layout shell, state adapter, section widgets, diagnostics contract, driver contract)

### Lint Integrity / No-Bypass Policy

- Completion requires both `flutter analyze` and `dart run custom_lint` to pass cleanly for the affected scope and final repo-wide gate
- The overhaul may not add `// ignore:`, `// ignore_for_file:`, analyzer `exclude:` entries, severity downgrades, per-file allowlists, or similar escape hatches to suppress design-system or structural findings
- The only standing scope carve-outs are spec-approved wrapper layers such as `design_system/` internals and test-only contexts already called out by the lint rules themselves
- If a lint is too noisy or incorrect, fix the rule or the code; do not mute it

---

## 5. Animation & Motion System

### New Animation Components (`design_system/animation/`)

| Component | Purpose | Trigger |
|-----------|---------|---------|
| `AppAnimatedEntrance` | Fade + slide-up. Reads duration/curve from `FieldGuideMotion.of(context)`. | Widget mount |
| `AppStaggeredList` | Staggers child entrances — 50ms delay per item (max 8, then batch). | List population |
| `AppTapFeedback` | Scale-to-0.95 on press, 1.0 on release. 100ms via motion tokens. | Tap down/up |
| `AppValueTransition` | Animated counter — slide-up old, slide-in new. | Value change |

### Screen Transitions

| Current | Target |
|---------|--------|
| Default `MaterialPageRoute` | `SharedAxisTransition` (horizontal) for peer screens |
| No tab transition | `FadeThroughTransition` for tab switches |
| No card-to-detail | `ContainerTransform` for card → detail screen |
| No motion token integration | Custom `TransitionPage` in GoRouter reading `FieldGuideMotion` tokens |

### Micro-Interactions

| Interaction | Widget | Technique | Duration |
|-------------|--------|-----------|----------|
| Card tap | `AppGlassCard`, `AppListTile` | `AppTapFeedback` — scale + elevation | 100ms |
| List item appear | All list screens | `AppStaggeredList` — fade + slide | 300ms staggered |
| Tab switch | Bottom nav, form tabs | `FadeThroughTransition` | 200ms |
| Value change | Budgets, counts, amounts | `AppValueTransition` — slide swap | 200ms |
| Expand/collapse | `AppSectionCard` | Verify uses motion tokens | 250ms |
| Chip appear/disappear | Status, filter chips | `AnimatedSwitcher` — scale + fade | 150ms |
| Progress fill | `AppProgressBar` | `TweenAnimationBuilder` | 300ms |

### Accessibility

When `MediaQuery.of(context).disableAnimations` is true, swap to `FieldGuideMotion.reduced` (all durations zero, linear curves). Every animation component checks automatically via token.

---

## 6. Screen Decomposition Plan

### Priority Batch (11 highest-cost files)

| # | Screen | Lines | Target | GitHub Issues Fixed |
|---|--------|-------|--------|-------------------|
| 1 | `entry_editor_screen.dart` | 1,857 | ~300 + 6 widgets | — |
| 2 | `project_setup_screen.dart` | 1,436 | ~300 + 5 widgets | #165 (RenderFlex) |
| 3 | `home_screen.dart` | 1,270 | ~300 + 4 widgets | — |
| 4 | `mdot_hub_screen.dart` | 1,198 | ~300 + 5 screens + form primitives | — |
| 5 | `project_list_screen.dart` | 1,196 | ~300 + 4 widgets | — |
| 6 | `contractor_editor_widget.dart` | 1,099 | ~300 + 3 widgets + 2 dialogs | — |
| 7 | `todos_screen.dart` | 891 | ~300 + 3 widgets | — |
| 8 | `calculator_screen.dart` | 712 | ~300 + 3 widgets | — |
| 9 | `project_dashboard_screen.dart` | 696 | ~300 + 3 widgets | #200, #207, #208, #233 |
| 10 | `quantity_calculator_screen.dart` | 656 | ~300 + 2 widgets | — |
| 11 | `form_viewer_screen.dart` | 636 | ~300 + 2 widgets | — |

These 11 files are the first-priority batch, not the full scope boundary. The overhaul continues through the remaining oversized UI screens and widgets until the design-system thresholds are met across the entire UI layer.

### Additional Audited UI Files Already In Scope

The following are explicitly in-scope follow-up targets after or alongside the priority batch because they remain oversized and/or design-system inconsistent:

- Screens: `gallery_screen.dart`, `pdf_import_preview_screen.dart`, `entries_list_screen.dart`, `quantities_screen.dart`, `admin_dashboard_screen.dart`, `settings_screen.dart`, `company_setup_screen.dart`
- Widgets: `entry_contractors_section.dart`, `entry_quantities_section.dart`, `hub_proctor_content.dart`, `entry_forms_section.dart`, `photo_detail_dialog.dart`, `member_detail_sheet.dart`, `entry_photos_section.dart`, `photo_name_dialog.dart`

### Remaining GitHub Issues

| Issue | Fixed During |
|-------|-------------|
| #209 — Forms list internal ID | Forms list tokenization + entry/date-based labeling |
| #202 — Quantity picker search not cleared | Quantities decomposition |
| #203 — Quantities + button workflow | Quantities decomposition |
| #201 — Android keyboard blocks buttons | Responsive layout pass |
| #238 — `no_inline_text_style` 6 violations | Pay apps tokenization |

### Decomposition Protocol (per screen/widget)

1. **Component discovery sweep** — grep for private widgets, cross-reference design system
2. **Promote shared patterns** — `_*Card`/`_*Tile`/`_*Badge` in 2+ features → design system
3. **Extract private widgets** — `_build*` methods → standalone widget files
4. **Tokenize** — replace all magic numbers, hardcoded colors, inline styles
5. **Sliver-ify** — convert scrolling to `CustomScrollView` + slivers
6. **Selector-ify** — replace `Consumer` with `Selector`
7. **Add motion** — staggered entrances, tap feedback, transitions
8. **Responsive layout** — `AppResponsiveBuilder` / canonical layout
9. **Close issues** — fix GitHub issues touching this screen, close via commit
10. **Update HTTP driver** — driver endpoints and testing keys for new structure
11. **Update logs** — new components log via `Logger`

---

## 7. Design System Component Inventory

### Current (24 components in flat `design_system/`)

Atomic: `AppText`, `AppTextField`, `AppChip`, `AppProgressBar`, `AppCounterField`, `AppToggle`, `AppIcon`
Card: `AppGlassCard`, `AppSectionHeader`, `AppListTile`, `AppPhotoGrid`, `AppSectionCard`
Surface: `AppScaffold`, `AppBottomBar`, `AppBottomSheet`, `AppDialog`, `AppStickyHeader`, `AppDragHandle`
Composite: `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppBudgetWarningChip`, `AppInfoBanner`, `AppMiniSpinner`

### Target (~56 components in atomic subdirectories)

**Tokens (6):**
`FieldGuideColors`, `FieldGuideSpacing`, `FieldGuideRadii`, `FieldGuideMotion`, `FieldGuideShadows`, `DesignConstants` (static fallback)

**Atoms (12):**
Existing: `AppText`, `AppChip`, `AppProgressBar`, `AppToggle`, `AppIcon`, `AppMiniSpinner`
New: `AppButton` (primary/secondary/ghost/danger variants), `AppBadge` (color/icon/letter variants), `AppDivider`, `AppAvatar`, `AppTooltip`

**Molecules (9):**
Existing: `AppTextField`, `AppCounterField`, `AppListTile`, `AppSectionHeader`
Migrated: `AppSearchBar` (from shared)
New: `AppDropdown`, `AppDatePicker`, `AppTabBar`

**Organisms (7):**
Existing: `AppGlassCard`, `AppSectionCard`, `AppPhotoGrid`, `AppInfoBanner`
New: `AppStatCard`, `AppActionCard`, form editor primitives (`AppFormSection`, `AppFormSectionNav`, `AppFormStatusBar`, `AppFormFieldGroup`, `AppFormSummaryTile`, `AppFormThumbnail`)

**Surfaces (6):**
Existing: `AppScaffold`, `AppBottomBar`, `AppBottomSheet`, `AppDialog`, `AppStickyHeader`, `AppDragHandle`

**Feedback (7):**
Existing: `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppBudgetWarningChip`
Migrated: `AppSnackbar` (from shared), `AppContextualFeedback` (from shared)
New: `AppBanner` (generic composable banner)

**Layout (5):**
New: `AppBreakpoint`, `AppResponsiveBuilder`, `AppAdaptiveLayout`, `AppResponsivePadding`, `AppResponsiveGrid`

**Animation (4):**
New: `AppAnimatedEntrance`, `AppStaggeredList`, `AppTapFeedback`, `AppValueTransition`

### Target Folder Structure

```
lib/core/design_system/
├── design_system.dart          (barrel)
├── tokens/
│   ├── tokens.dart             (barrel)
│   ├── app_colors.dart         (moved from theme/)
│   ├── design_constants.dart   (moved from theme/)
│   ├── field_guide_colors.dart (moved from theme/)
│   ├── field_guide_spacing.dart
│   ├── field_guide_radii.dart
│   ├── field_guide_motion.dart
│   └── field_guide_shadows.dart
├── atoms/
│   ├── app_text.dart
│   ├── app_icon.dart
│   ├── app_chip.dart
│   ├── app_toggle.dart
│   ├── app_progress_bar.dart
│   ├── app_mini_spinner.dart
│   ├── app_button.dart         (NEW)
│   ├── app_badge.dart          (NEW)
│   ├── app_divider.dart        (NEW)
│   ├── app_avatar.dart         (NEW)
│   └── app_tooltip.dart        (NEW)
├── molecules/
│   ├── app_text_field.dart
│   ├── app_counter_field.dart
│   ├── app_list_tile.dart
│   ├── app_section_header.dart
│   ├── app_search_bar.dart     (migrated from shared)
│   ├── app_dropdown.dart       (NEW)
│   ├── app_date_picker.dart    (NEW)
│   └── app_tab_bar.dart        (NEW)
├── organisms/
│   ├── app_glass_card.dart
│   ├── app_section_card.dart
│   ├── app_photo_grid.dart
│   ├── app_info_banner.dart
│   ├── app_stat_card.dart      (NEW)
│   ├── app_action_card.dart    (NEW)
│   ├── app_form_section.dart   (NEW — form editor)
│   ├── app_form_section_nav.dart (NEW — form editor)
│   ├── app_form_status_bar.dart  (NEW — form editor)
│   ├── app_form_field_group.dart (NEW — form editor)
│   ├── app_form_summary_tile.dart (NEW — form editor)
│   └── app_form_thumbnail.dart   (NEW — form editor)
├── surfaces/
│   ├── app_scaffold.dart
│   ├── app_bottom_bar.dart
│   ├── app_bottom_sheet.dart
│   ├── app_dialog.dart
│   ├── app_sticky_header.dart
│   └── app_drag_handle.dart
├── feedback/
│   ├── app_empty_state.dart
│   ├── app_error_state.dart
│   ├── app_loading_state.dart
│   ├── app_budget_warning_chip.dart
│   ├── app_snackbar.dart       (migrated from shared)
│   ├── app_contextual_feedback.dart (migrated from shared)
│   └── app_banner.dart         (NEW)
├── layout/
│   ├── app_breakpoint.dart     (NEW)
│   ├── app_responsive_builder.dart (NEW)
│   ├── app_adaptive_layout.dart    (NEW)
│   ├── app_responsive_padding.dart (NEW)
│   └── app_responsive_grid.dart    (NEW)
└── animation/
    ├── app_animated_entrance.dart  (NEW)
    ├── app_staggered_list.dart     (NEW)
    ├── app_tap_feedback.dart       (NEW)
    └── app_value_transition.dart   (NEW)
```

---

## 8. Documentation & Testing Updates

### Architecture Documentation

| File | Update |
|------|--------|
| `.claude/CLAUDE.md` | Component count, folder structure, token system, 2 themes not 3, new lint rules in anti-patterns |
| `.claude/docs/directory-reference.md` | New `design_system/` subdirectory structure |
| `.claude/skills/implement/references/architecture-guide.md` | Color system, token patterns, responsive layout, component inventory |
| `.claude/skills/implement/references/worker-rules.md` | Token usage rules, component selection, responsive patterns |
| `.claude/skills/implement/references/reviewer-rules.md` | Token violations, raw widget usage, missing responsive handling |
| `.claude/rules/architecture.md` | New lint rule anti-patterns, token/responsive requirements |

### HTTP Driver Updates

| Update | Why |
|--------|-----|
| `TestingKeys` for all new design system components | Driver needs to find widgets by key |
| Update screen test flows for decomposed structure | Widget selectors may change |
| Keep `screen_registry.dart` aligned with every decomposed screen shell and extracted child screen that must be harness-bootable | Sync coordinators/orchestrators and driver flows need stable screen bootstrapping after decomposition |
| Keep `flow_registry.dart` aligned with route moves and screen splits | Sync verification flows must remain declarative and route-stable |
| Responsive testing endpoints | Verify layouts at different breakpoints |
| Navigation mode diagnostics | Driver needs to distinguish bottom-nav vs navigation-rail shells |
| Density diagnostics | Debug server and tests need to know which density variant is active |
| Animation-aware waits | Staggered entrances need settling time |
| Log new component hierarchy | Debug server shows design system components on screen |
| Screen contract diagnostics endpoint | Sync verification needs the current screen id, root sentinel key, and exposed contract metadata without tree-dump archaeology |

### Logging Updates

| Update | Why |
|--------|-----|
| `Logger.ui` category | Component lifecycle debugging |
| Log responsive breakpoint changes | When screen crosses breakpoint |
| Log density variant switches | When token set changes |
| Log animation duration overrides | When `reduceMotion` activates |
| Debug server UI diagnostics | Breakpoint, density, theme, animation state |

### Testing

| Area | Update |
|------|--------|
| Widget tests | Every new component gets tests covering all variants, themes, breakpoints |
| Golden tests | Baselines for new components across dark/light and phone/tablet; remove/update obsolete high-contrast baselines |
| Widgetbook use cases | Each design system component gets a use case with knobs |
| Integration tests | Update for decomposed widget structure |
| Responsive tests | Test canonical layouts at each breakpoint |
| Performance tests | Baseline frame times, fail on regression |
| Sync verification harness | Revalidate sync-sensitive flows against the updated screen contracts, route registries, and diagnostics endpoints so UI decomposition does not break coordinator/orchestrator verification |

### Widgetbook Setup

| Decision | Choice |
|----------|--------|
| Location | `widgetbook/` at project root |
| Scope | All design system components + key feature widgets |
| Knobs | Theme (dark/light), breakpoint (compact/medium/expanded/large), density (compact/standard/comfortable) |
| Device frames | Phone (Samsung S21), Tablet (iPad 10.9"), Desktop (1440x900) |
| CI | Build Widgetbook on every PR |

---

## 9. Migration/Cleanup

### Dead Code Removal

| Code | Action |
|------|--------|
| `AppTheme.highContrastTheme` (~500 lines) | Delete |
| `FieldGuideColors.highContrast` | Delete |
| `AppColors.hc*` (12 constants) | Delete |
| `AppThemeMode.highContrast` and Settings theme selection UI | Delete |
| High-contrast `TestingKeys` and persisted theme fallback | Remove/update so old saved preferences fall back safely to dark |
| High-contrast tests and goldens | Delete or regenerate for 2-theme system |
| `AppTheme` deprecated re-exports (~20 fields) | Delete |
| `shared/widgets/empty_state_widget.dart` | Merge into `AppEmptyState`, delete |
| `shared/widgets/confirmation_dialog.dart` | Merge into `AppDialog.showConfirmation()`, delete |
| `shared/widgets/stale_config_warning.dart` | Recompose from `AppBanner`, delete |
| `shared/widgets/version_banner.dart` | Recompose from `AppBanner`, delete |
| Private `_*Card`/`_*Badge` replaced by design system | Delete from feature files |

### File Moves

| From | To |
|------|-----|
| `lib/core/theme/field_guide_colors.dart` | `lib/core/design_system/tokens/field_guide_colors.dart` |
| `lib/core/theme/design_constants.dart` | `lib/core/design_system/tokens/design_constants.dart` |
| `lib/core/theme/colors.dart` | `lib/core/design_system/tokens/app_colors.dart` |
| `lib/shared/utils/snackbar_helper.dart` | `lib/core/design_system/feedback/app_snackbar.dart` |
| `lib/shared/widgets/search_bar_field.dart` | `lib/core/design_system/molecules/app_search_bar.dart` |
| `lib/shared/widgets/contextual_feedback_overlay.dart` | `lib/core/design_system/feedback/app_contextual_feedback.dart` |

### Import Migration

- Barrel file re-exports everything — consumers use single import
- Token barrel re-exports all token extensions
- `dart fix --apply` after each move batch
- Zero analyzer errors after each batch

---

## 10. Implementation Phasing

| Phase | What | Batches |
|-------|------|---------|
| **P0: Lint rules** | Implement 10 new lint rules at warning severity. Run analysis for complete violation inventory, lock the no-bypass policy, and inventory the sync-facing screen contracts that must survive the refactor. | 1 |
| **P1: Tokens + Theme** | Build 5 ThemeExtensions, kill HC theme, collapse `app_theme.dart`, create folder structure, move token files | 1-2 |
| **P2: Infrastructure** | Responsive breakpoints, canonical layouts, animation wrappers, navigation adaptation, Widgetbook skeleton | 2-3 |
| **P3: Design system expansion** | New components (button, badge, divider, banner, dropdown, etc.), migrate shared widgets | 2-3 |
| **P4: UI decomposition** | Decompose the 11 priority files first, then continue through remaining oversized UI screens/widgets with full protocol (tokenize, sliver-ify, Selector-ify, motion, responsive, fix issues). Component discovery sweep each batch. Enforce the 300-line ceiling across extracted helpers/controllers/mixins too, and keep screen contracts/driver registries in sync as screens split. | 5-8 |
| **P5: Performance** | Profile 5 worst screens, fix bottlenecks, systematic pattern pass, re-profile | 1-2 |
| **P6: Polish** | Desktop hover/focus, Widgetbook completion, documentation updates, driver/logging updates, golden baselines, flip lint rules to error, and prove the final lint/driver/screen-contract gates without suppression shortcuts | 2-3 |

### Cleanup Checklist (end of each phase)

- [ ] Zero analyzer errors
- [ ] Zero new lint violations
- [ ] All moved files have updated imports
- [ ] Barrel files reflect current exports
- [ ] No orphaned files
- [ ] Documentation updated
- [ ] GitHub issues closed for completed fixes
- [ ] `screen_registry.dart`, `flow_registry.dart`, and sync-relevant `TestingKeys` reflect the current decomposed UI
- [ ] No new lint suppressions, analyzer excludes, or severity downgrades were introduced to make the phase pass

---

## 11. GitHub Issues Addressed

| # | Title | Fixed In |
|---|-------|----------|
| 238 | `no_inline_text_style` — 6 violations | P4: Pay apps tokenization |
| 208 | Dashboard gradient out of place | P4: Dashboard decomposition |
| 207 | Dashboard empty-state button contrast | P4: Dashboard decomposition |
| 209 | Forms list shows internal ID | P4: Forms tokenization + entry/date-based labeling |
| 200 | Review Drafts tile-card style | P4: Dashboard decomposition |
| 199 | Review Drafts no delete action | P4: Dashboard decomposition |
| 203 | Quantities + button workflow | P4: Quantities decomposition |
| 202 | Quantity picker search not cleared | P4: Quantities decomposition |
| 201 | Android keyboard blocks buttons | P2: Responsive layout |
| 165 | RenderFlex overflow errors | P4: Project setup decomposition |
| 233 | Dashboard/calendar/projects button consistency | P4: Dashboard decomposition |

---

## 12. Violation Inventory (Initial Baseline from Audit)

| Category | Count | Files |
|----------|-------|-------|
| `Colors.*` hardcoded | 44 | 30 |
| `BorderRadius.circular(N)` magic numbers | 51 | 27 |
| `EdgeInsets.*(N)` magic numbers | 41 | 22 |
| `SizedBox(width/height: N)` magic numbers | 249 | 57 |
| `TextStyle(` inline | 3 | 2 |
| Screens > 400 lines | 25 | — |
| Screens > 600 lines | 14 | — |
| Screens > 1,000 lines | 6 | — |
| `app_theme.dart` | 1,777 lines | 1 |

These counts are directional only and may drift as the codebase changes. P0 lint rules produce the definitive, per-rule inventory that drives the actual refactor contract.
