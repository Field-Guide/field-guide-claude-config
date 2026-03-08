# UI Refactor Reference Document

**Date**: 2026-03-06
**Scope**: Full presentation layer audit across all 17 features
**Sources**: Theme token audit, CodeMunch dependency map, UI Explorer navigation/layout analysis

---

## 1. Current State Summary

### UI Architecture Overview

The Field Guide App uses a feature-first architecture with 38 screen classes, 80+ presentation widgets, and ~40 modal surfaces (sheets + dialogs). Navigation is handled by go_router with a 4-tab shell route (Dashboard, Calendar/Home, Projects, Settings) and 25+ full-screen routes outside the shell. All screens use `Scaffold`.

The theme system lives in `lib/core/theme/` with three complete `ThemeData` builders (dark, light, high contrast) totaling ~1,500 lines. Tokens are defined in `AppColors` (colors) and `DesignConstants` (spacing, radius, elevation, animation) and re-exported through an `AppTheme` facade class. Material 3 is enabled (`useMaterial3: true`).

### What Is Working Well

- **Theme facade pattern**: Presentation code correctly uses `AppTheme.*` (never `AppColors.*` or `DesignConstants.*` directly). Zero `Color(0x...)` hex literals in presentation. Zero `AppColors.*` direct imports in presentation. This facade is clean and consistent.
- **Color token library is comprehensive**: 51 color tokens across primary, accent, semantic, surface, text, weather, and overlay categories. All three theme modes (dark, light, high contrast) have complete `ThemeData` with all component themes defined.
- **Auth screens are the gold standard**: `login_screen.dart`, `pending_approval_screen.dart`, and all auth screens use `AppTheme.space*` for spacing, `textTheme.*` for typography, `AppTheme.*` for colors, and `SafeArea` on body. These should be the template for all other screens.
- **Well-tokenized reference files exist**: `entry_form_card.dart`, `bid_item_detail_sheet.dart`, and the `toolbox` feature use `AppTheme.space*` throughout. The calculator and toolbox features have near-zero violations.
- **No custom icon sets or SVGs**: All 458 icon references use standard Material `Icons.*` constants, keeping the icon story simple.

### What Is Broken

- **Typography is the biggest gap**: The `textTheme` is fully defined (15 slots, all three modes) but only consumed in 17 files via `Theme.of(context).textTheme.*` (33 total uses). Meanwhile, 179+ inline `TextStyle(fontSize: N)` instances exist across 58+ files. Typography is effectively not tokenized.
- **Hardcoded dimensions are pervasive**: 200+ raw `SizedBox(height: N)`, 179 raw `EdgeInsets` with numeric literals, and 70+ raw `BorderRadius.circular(N)` -- all despite existing tokens that match the values.
- **40+ `Colors.*` violations**: Flutter's `Colors.red`, `Colors.grey`, `Colors.white`, `Colors.amber`, `Colors.green`, `Colors.orange` used directly instead of `AppTheme.status*` / `AppTheme.text*` tokens.
- **6 confirmed bottom-cutoff bugs**: Screens using `bottomNavigationBar` without `SafeArea`, sheets using `viewInsets` instead of `viewPadding`, and insufficient bottom padding.
- **Inconsistent patterns**: Section headers have 3+ different implementations. Drag handle bars are inconsistent between sheets. Error states are duplicated in 3+ screens. Budget discrepancy chips are copy-pasted between features.

---

## 2. Scale of Change

| Metric | Count |
|--------|-------|
| Total screens | 38 |
| Total presentation widgets | 80+ |
| Total modal surfaces (sheets + dialogs) | ~40 (8 bottom sheets + ~30 dialogs + 2 DraggableScrollableSheet) |
| Total routes | 35 |
| Total providers | 20 |
| Total `AppTheme.*` references (existing adoption) | 1,330+ |

### Files Needing Changes by Severity

| Severity | Count | Description |
|----------|-------|-------------|
| **HIGH** | 8 | Multiple violation categories, raw Colors + raw fontSize + raw spacing. Sync screens, admin dashboard, project list, gallery viewer. |
| **MEDIUM** | 20 | 2-3 violation categories, significant hardcoded values but some token adoption. Most entry widgets, settings screens, PDF screens, forms widgets. |
| **LOW** | 15 | Mostly tokenized, 1-2 minor violations (a stray fontSize or BorderRadius). Home screen (partially), entry editor, some auth screens. |
| **NONE** | 5 | Fully tokenized. TodosScreen, ToolboxHomeScreen, EditProfileScreen (mostly), QuantityCalculatorScreen, calculator widgets. |

### Estimated Total Violations

| Category | Est. Count |
|----------|-----------|
| `Colors.*` (non-transparent, non-shadow) | ~55 instances in ~25 files |
| Inline `TextStyle(fontSize: N)` | 179+ instances in 58+ files |
| Raw `SizedBox(height: N)` | 200+ instances in 60+ files |
| Raw `EdgeInsets` with literals | 179 instances in 58 files |
| Raw `BorderRadius.circular(N)` | 70+ instances in 35+ files |
| Raw `FontWeight.*` inline | 40+ instances |
| Raw icon `size:` values | 150 instances in 55 files |

---

## 3. Theme System Assessment

### 3a. Existing Token Inventory

**Location**: `lib/core/theme/app_theme.dart` (facade), `lib/core/theme/colors.dart`, `lib/core/theme/design_constants.dart`

#### Color Tokens (51 total, via AppTheme re-exports)

| Group | Tokens | Count |
|-------|--------|-------|
| Primary | `primaryCyan` (#00E5FF), `primaryBlue` (#2196F3), `primaryDark` (#0277BD), `primaryLight` (#80D8FF) | 4 |
| Accent | `accentAmber` (#FFB300), `accentOrange` (#FF6F00), `accentGold` (#FFD54F) | 3 |
| Semantic/Status | `statusSuccess` (#4CAF50), `statusWarning` (#FF9800), `statusError` (#F44336), `statusInfo` (#2196F3) | 4 |
| Legacy aliases | `secondaryAmber`, `success`, `warning`, `error` | 4 |
| Dark surfaces (6 levels) | `backgroundDark`, `surfaceDark`, `surfaceElevated`, `surfaceHighlight`, `surfaceBright`, `surfaceGlass` | 6 |
| Dark text (4 levels) | `textPrimary`, `textSecondary`, `textTertiary`, `textInverse` | 4 |
| Light surfaces | `lightBackground`, `lightSurface`, `lightSurfaceElevated`, `lightSurfaceHighlight` | 4 |
| Light text | `lightTextPrimary`, `lightTextSecondary`, `lightTextTertiary` | 3 |
| High Contrast | `hcBackground`, `hcSurface`, `hcSurfaceElevated`, `hcBorder`, `hcPrimary`, `hcAccent`, `hcError`, `hcWarning`, `hcTextPrimary`, `hcTextSecondary` | 10 |
| Weather | `weatherSunny`, `weatherCloudy`, `weatherOvercast`, `weatherRainy`, `weatherSnow`, `weatherWindy` | 6 |
| Overlay | `overlayLight` | 1 |
| Gradients | `gradientPrimary`, `gradientAccent` | 2 |

#### Spacing Tokens (8 re-exported, 2 not re-exported)

| Token | Value | In AppTheme? |
|-------|-------|-------------|
| `space1` | 4.0 | Yes |
| `space2` | 8.0 | Yes |
| `space3` | 12.0 | Yes |
| `space4` | 16.0 | Yes |
| `space5` | 20.0 | Yes |
| `space6` | 24.0 | Yes |
| `space8` | 32.0 | Yes |
| `space10` | 40.0 | Yes |
| `DesignConstants.space12` | 48.0 | **NO** |
| `DesignConstants.space16` | 64.0 | **NO** |

#### Radius Tokens (5 total)

| Token | Value |
|-------|-------|
| `radiusSmall` | 8.0 |
| `radiusMedium` | 12.0 |
| `radiusLarge` | 16.0 |
| `radiusXLarge` | 24.0 |
| `radiusFull` | 999.0 |

#### Elevation Tokens (4 total)

| Token | Value |
|-------|-------|
| `elevationLow` | 2.0 |
| `elevationMedium` | 4.0 |
| `elevationHigh` | 8.0 |
| `elevationModal` | 16.0 |

#### Touch Target Tokens (3 total)

| Token | Value |
|-------|-------|
| `touchTargetMin` | 48.0 |
| `touchTargetComfortable` | 56.0 |
| `touchTargetLarge` | 64.0 |

#### Animation Tokens (5 re-exported, 4 not re-exported)

| Token | Value | In AppTheme? |
|-------|-------|-------------|
| `animationFast` | 150ms | Yes |
| `animationNormal` | 300ms | Yes |
| `animationSlow` | 500ms | Yes |
| `curveDefault` | easeInOutCubic | Yes |
| `curveSpring` | easeOutBack | Yes |
| `DesignConstants.animationPageTransition` | 350ms | **NO** |
| `DesignConstants.curveDecelerate` | easeOut | **NO** |
| `DesignConstants.curveAccelerate` | easeIn | **NO** |
| `DesignConstants.curveBounce` | elasticOut | **NO** |

#### Text Theme (15 Material 3 slots, all defined in all 3 themes)

| Slot | Dark Size/Weight | Usage Intent |
|------|-----------------|--------------|
| `displayLarge` | 57/w700 | Hero text |
| `displayMedium` | 45/w600 | Large display |
| `displaySmall` | 36/w600 | Medium display |
| `headlineLarge` | 32/w700 | Screen titles |
| `headlineMedium` | 28/w700 | Major section heads |
| `headlineSmall` | 24/w700 | Minor section heads |
| `titleLarge` | 22/w700 | Card/dialog titles |
| `titleMedium` | 16/w700 | List titles, section headers |
| `titleSmall` | 14/w700 | Small section labels |
| `bodyLarge` | 16/w400 | Primary content |
| `bodyMedium` | 14/w400 | Secondary content |
| `bodySmall` | 12/w400 | Captions |
| `labelLarge` | 14/w700 | Buttons, tags |
| `labelMedium` | 12/w700 | Labels |
| `labelSmall` | 11/w700 | Mini tags |

### 3b. Token Gap Analysis -- What Is MISSING

| Suggested Token | Value | Rationale |
|----------------|-------|-----------|
| `AppTheme.space12` | 48.0 | Exists in `DesignConstants` but NOT re-exported |
| `AppTheme.space16` | 64.0 | Exists in `DesignConstants` but NOT re-exported |
| `AppTheme.radiusXSmall` | 4.0 | Used in ~12 places for chips/badges/small elements |
| `AppTheme.radiusCompact` | 6.0 or 10.0 | Used in project list cards and hub widgets |
| `AppTheme.iconSizeSmall` | 18.0 | Very common inline icon size |
| `AppTheme.iconSizeMedium` | 24.0 | Material default, should be explicit constant |
| `AppTheme.iconSizeLarge` | 32.0 | Large state icons |
| `AppTheme.iconSizeXL` | 48.0 | Empty state and hero icons |
| `AppTheme.overlayDark` | Color(0x8AFFFFFF) | Defined in `AppColors` but NOT re-exported |
| `AppColors.gradientSuccess` | green gradient | Defined in `AppColors` but NOT re-exported |
| `AppTheme.statusNeutral` | maps to `textSecondary` | Needed for "never synced" / inactive states |
| `AppTheme.warningBackground` | amber.shade50 equiv | Warning chip background (used in dashboard + quantities identically) |
| `AppTheme.warningBorder` | amber.shade200 equiv | Warning chip border (same 2 features) |
| `AppTheme.animationPageTransition` | 350ms | In `DesignConstants` but NOT in `AppTheme` |
| `AppTheme.curveDecelerate` | Curves.easeOut | In `DesignConstants` but NOT in `AppTheme` |
| `AppTheme.curveAccelerate` | Curves.easeIn | In `DesignConstants` but NOT in `AppTheme` |
| `AppTheme.curveBounce` | Curves.elasticOut | In `DesignConstants` but NOT in `AppTheme` |

### 3c. Typography Gap (the biggest hole)

**33 uses** of `Theme.of(context).textTheme.*` across 17 files vs **179+ inline `TextStyle()`** across 58+ files. The textTheme is well-defined but almost never consumed.

Files with the most theme-based text style usage (positive examples):
- `otp_verification_screen.dart` -- 3 uses
- `login_screen.dart` -- 2 uses
- `home_screen.dart` -- 1 use

Most common inline fontSize values that map directly to existing textTheme slots:
| Inline fontSize | Nearest textTheme slot | Est. instances |
|----------------|----------------------|---------------|
| 11 | `labelSmall` (11/w700) | ~15 |
| 12 | `bodySmall` (12/w400) | ~35+ |
| 14 | `bodyMedium` (14/w400) or `labelLarge` (14/w700) | ~25+ |
| 16 | `bodyLarge` (16/w400) or `titleMedium` (16/w700) | ~20+ |
| 22 | `titleLarge` (22/w700) | ~3 |
| 36 | `displaySmall` (36/w600) | ~1 |

Problematic sizes with no direct textTheme mapping:
| Inline fontSize | Gap |
|----------------|-----|
| 10 | Below `labelSmall` (11) |
| 13 | Between `bodySmall` (12) and `bodyMedium` (14) |
| 15 | Between `bodyMedium` (14) and `bodyLarge` (16) |
| 18 | Between `bodyLarge` (16) and `titleLarge` (22) -- gap in headlineSmall |
| 20 | Between `bodyLarge` (16) and `titleLarge` (22) |

### 3d. Spacing Adoption Rate by Feature

| Feature | AppTheme.space* uses | Raw number uses | Adoption % |
|---------|---------------------|-----------------|-----------|
| `toolbox` | High | Low | ~75% |
| `calculator` | High | Medium | ~65% |
| `auth` | High | Medium | ~60% |
| `gallery` | High | Medium | ~55% |
| `quantities` | High | Medium | ~55% |
| `entries` (home_screen) | Very High (66 uses) | Very High | ~55% |
| `dashboard` | High | High | ~50% |
| `todos` | High | High | ~50% |
| `settings` | Medium | High | ~40% |
| `entries` (widgets) | Medium | Very High | ~35% |
| `forms` | Low | Very High | ~20% |
| `sync` | Low | High | ~20% |

### 3e. Color Adoption

- **91 files** use `AppTheme.*` color tokens (good)
- **~25 files** still have `Colors.*` violations (bad)
- Features with ZERO `Colors.*` violations: calculator, locations, photos (mostly), weather, todos, toolbox

---

## 4. Screen-by-Screen Inventory

### Auth Screens (10 screens -- outside shell, no bottom nav)

| # | Screen | File | Layout | SafeArea | Bottom Bar | Hardcoded Severity | Provider Deps | Notes |
|---|--------|------|--------|----------|------------|-------------------|---------------|-------|
| 1 | LoginScreen | `lib/features/auth/presentation/screens/login_screen.dart` | ListView | Yes | None | LOW | AuthProvider | Gold standard reference. Uses textTheme, AppTheme.space*, AppTheme colors. Only violation: `Colors.white` on button. |
| 2 | RegisterScreen | `lib/features/auth/presentation/screens/register_screen.dart` | ListView | Yes | None | LOW | AuthProvider | Same quality as login. |
| 3 | ForgotPasswordScreen | `lib/features/auth/presentation/screens/forgot_password_screen.dart` | ListView | Yes | None | LOW | AuthProvider | Well tokenized. |
| 4 | OtpVerificationScreen | `lib/features/auth/presentation/screens/otp_verification_screen.dart` | ListView | Yes | None | LOW | AuthProvider | 3 textTheme uses -- best in app. |
| 5 | UpdatePasswordScreen | `lib/features/auth/presentation/screens/update_password_screen.dart` | ListView | Yes | None | LOW | AuthProvider | Well tokenized. |
| 6 | UpdateRequiredScreen | `lib/features/auth/presentation/screens/update_required_screen.dart` | Column | Yes | None | LOW | AppConfigProvider | 4 inline fontSize (13, 14). |
| 7 | ProfileSetupScreen | `lib/features/auth/presentation/screens/profile_setup_screen.dart` | ListView | Yes | None | LOW | AuthProvider | `Colors.white` on button:201. |
| 8 | CompanySetupScreen | `lib/features/auth/presentation/screens/company_setup_screen.dart` | ListView | Yes | None | LOW | AuthProvider, AuthService | `Colors.white` on buttons:277,387. |
| 9 | PendingApprovalScreen | `lib/features/auth/presentation/screens/pending_approval_screen.dart` | Column | Yes | None | NONE | AuthProvider, AuthService | Fully tokenized. Uses AppTheme.touchTargetComfortable. |
| 10 | AccountStatusScreen | `lib/features/auth/presentation/screens/account_status_screen.dart` | Column | Yes | None | NONE | AuthProvider | Fully tokenized. |

### Shell Route Screens (4 screens -- bottom nav bar)

| # | Screen | File | Layout | SafeArea | Bottom Bar | Hardcoded Severity | Provider Deps | Notes |
|---|--------|------|--------|----------|------------|-------------------|---------------|-------|
| 11 | ProjectDashboardScreen | `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart` | CustomScrollView | No | Shell nav | HIGH | ProjectProvider, DailyEntryProvider, LocationProvider, BidItemProvider, ContractorProvider, EntryQuantityProvider | 24 inline fontSize. `Colors.orange.shade800`:427, `Colors.amber.shade50`:432, `Colors.amber.shade200`:433, `Colors.black.withValues`:477, `Colors.transparent`:148,150. |
| 12 | HomeScreen | `lib/features/entries/presentation/screens/home_screen.dart` | CustomScrollView | No | Shell nav | MEDIUM | ProjectProvider, DailyEntryProvider, CalendarFormatProvider, LocationProvider, ContractorProvider, EquipmentProvider, PhotoProvider, AuthProvider, BidItemProvider, PersonnelTypeProvider, EntryQuantityProvider | 35+ inline fontSize. `Colors.transparent`:774-776,1954 (acceptable). Bottom cutoff bug in contractor picker sheet:1604. 2000+ line file -- largest screen. |
| 13 | ProjectListScreen | `lib/features/projects/presentation/screens/project_list_screen.dart` | ListView | No | Shell nav | HIGH | ProjectProvider, AuthProvider, DatabaseService | 15 inline fontSize (12,13,14,15,16). 5 raw BorderRadius (6,8,10,12). Zero Colors violations but heavy dimension violations. |
| 14 | SettingsScreen | `lib/features/settings/presentation/screens/settings_screen.dart` | ListView | No | Shell nav | MEDIUM | AuthProvider, ProjectSettingsProvider, AppConfigProvider, DatabaseService | `Colors.white`:223. `BorderRadius.circular(12)`:218. `fontSize: 11`:254, `fontSize: 12`:224. Bottom cutoff bug: `SizedBox(height: 32)`:339 insufficient. |

### Full-Screen Routes (24 screens -- outside shell)

| # | Screen | File | Layout | SafeArea | Bottom Bar | Hardcoded Severity | Provider Deps | Notes |
|---|--------|------|--------|----------|------------|-------------------|---------------|-------|
| 15 | EntryEditorScreen | `lib/features/entries/presentation/screens/entry_editor_screen.dart` | CustomScrollView | No | None | MEDIUM | 11 providers (DailyEntry, Location, Project, Contractor, Equipment, EntryQuantity, Photo, PersonnelType, InspectorForm, BidItem, Auth + DatabaseService) | Dependency hub. 5 inline fontSize (14,16). 3 raw BorderRadius (8,12). |
| 16 | EntriesListScreen | `lib/features/entries/presentation/screens/entries_list_screen.dart` | CustomScrollView | No | None | MEDIUM | ProjectProvider, DailyEntryProvider, LocationProvider, AuthProvider | 15 inline fontSize (12,13,14,16,18,20). 3 raw BorderRadius (8,12). |
| 17 | DraftsListScreen | `lib/features/entries/presentation/screens/drafts_list_screen.dart` | ListView | SafeArea on footer | None | LOW | DailyEntryProvider, LocationProvider | 2 inline fontSize (14,20). `Colors.black.withValues`:219 (shadow). |
| 18 | EntryReviewScreen | `lib/features/entries/presentation/screens/entry_review_screen.dart` | CustomScrollView | SafeArea on footer | None | LOW | LocationProvider | 2 inline fontSize (14,18). `Colors.black.withValues`:230 (shadow). |
| 19 | ReviewSummaryScreen | `lib/features/entries/presentation/screens/review_summary_screen.dart` | CustomScrollView | SafeArea on footer | None | MEDIUM | LocationProvider | 5 inline fontSize (11,13,14,20). `Colors.red`:91, `Colors.black.withValues`:167, `Colors.white`:187. |
| 20 | ProjectSetupScreen | `lib/features/projects/presentation/screens/project_setup_screen.dart` | CustomScrollView | No | None | MEDIUM | LocationProvider, ContractorProvider, EquipmentProvider, BidItemProvider, ProjectProvider, AuthProvider | 2 inline fontSize (10,12). 1 raw BorderRadius (4):415. |
| 21 | QuantitiesScreen | `lib/features/quantities/presentation/screens/quantities_screen.dart` | CustomScrollView | No | None | MEDIUM | ProjectProvider, BidItemProvider, EntryQuantityProvider, AuthProvider | 3 inline fontSize (12,13). `Colors.orange.shade800`:173, `Colors.amber.shade50`:178, `Colors.amber.shade200`:179 (duplicate of dashboard warning chip). |
| 22 | QuantityCalculatorScreen | `lib/features/quantities/presentation/screens/quantity_calculator_screen.dart` | Column | No | None | NONE | CalculatorProvider, ProjectProvider | Fully tokenized. |
| 23 | CalculatorScreen | `lib/features/calculator/presentation/screens/calculator_screen.dart` | Column | No | None | NONE | CalculatorProvider | Fully tokenized. |
| 24 | GalleryScreen | `lib/features/gallery/presentation/screens/gallery_screen.dart` | GridView | SafeArea on grid | None | HIGH | GalleryProvider, ProjectProvider | 4 inline fontSize (12,14,16). 9 raw `Colors.*` for photo viewer: `Colors.black`:549,551, `Colors.white`:552,555,601, `Colors.white54`:581,623, `Colors.black87`:593, `Colors.white70`:609,615. Photo viewer overlay colors are intentional but should still use named tokens. |
| 25 | FormsListScreen | `lib/features/forms/presentation/screens/forms_list_screen.dart` | Column | No | None | LOW | InspectorFormProvider, ProjectProvider, AuthProvider | 1 inline fontSize (18):118. |
| 26 | FormViewerScreen | `lib/features/forms/presentation/screens/form_viewer_screen.dart` | Column | No | None | NONE | InspectorFormProvider, ProjectProvider, AuthProvider, FormPdfService | Clean. |
| 27 | MdotHubScreen | `lib/features/forms/presentation/screens/mdot_hub_screen.dart` | CustomScrollView | No | None | LOW | InspectorFormProvider, ProjectProvider, AuthProvider, FormPdfService | Mostly tokenized, violations in child widgets. |
| 28 | TodosScreen | `lib/features/todos/presentation/screens/todos_screen.dart` | ListView | No | None | LOW | TodoProvider, ProjectProvider, AuthProvider | 2 raw BorderRadius (12):131,579. Otherwise well tokenized. |
| 29 | ToolboxHomeScreen | `lib/features/toolbox/presentation/screens/toolbox_home_screen.dart` | Column | No | None | NONE | None | Fully tokenized. |
| 30 | PdfImportPreviewScreen | `lib/features/pdf/presentation/screens/pdf_import_preview_screen.dart` | Column | No | bottomNavigationBar | MEDIUM | Via extra params | 15 inline fontSize (11,12,13,14,16). 1 raw BorderRadius (4):423. **Bottom cutoff bug**: bottomNavigationBar Container with `EdgeInsets.all(16)`:195, no SafeArea. |
| 31 | MpImportPreviewScreen | `lib/features/pdf/presentation/screens/mp_import_preview_screen.dart` | Column | No | bottomNavigationBar | MEDIUM | Via extra params | 4 inline fontSize (10,12,16). **Bottom cutoff bug**: bottomNavigationBar Container, no SafeArea:72. |
| 32 | TrashScreen | `lib/features/settings/presentation/screens/trash_screen.dart` | ListView | No | None | MEDIUM | DatabaseService | 6 inline fontSize (12,14,18). |
| 33 | EditProfileScreen | `lib/features/settings/presentation/screens/edit_profile_screen.dart` | ListView | Yes | None | LOW | AuthProvider | `Colors.white`:240 on button. Otherwise tokenized. |
| 34 | AdminDashboardScreen | `lib/features/settings/presentation/screens/admin_dashboard_screen.dart` | ListView | No | None | HIGH | AdminProvider, AuthProvider | 3 inline fontSize (11,12). 3 raw BorderRadius (4,12). 5 `Colors.*` violations: `Colors.grey`:90,109,265,281, `Colors.white`:148. |
| 35 | PersonnelTypesScreen | `lib/features/settings/presentation/screens/personnel_types_screen.dart` | ListView | No | None | MEDIUM | PersonnelTypeProvider | 1 inline fontSize (18). |
| 36 | SyncDashboardScreen | `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` | ListView | No | None | HIGH | SyncProvider, DatabaseService | 9 inline fontSize (11,12,13,16,20). 7 `Colors.*` violations: `Colors.red`:161, `Colors.amber`:163, `Colors.green`:164, `Colors.grey`:208,395, `Colors.white`:305, `Colors.orange`:384. Worst offender file overall. |
| 37 | ConflictViewerScreen | `lib/features/sync/presentation/screens/conflict_viewer_screen.dart` | ListView | No | None | HIGH | DatabaseService, SyncRegistry | 3 inline fontSize (11,12,13). 1 raw BorderRadius (4):278. 4 `Colors.*` violations: `Colors.green`:188, `Colors.orange`:232, `Colors.grey`:261, `Colors.grey.shade100`:277. |
| 38 | ProjectSelectionScreen | `lib/features/sync/presentation/screens/project_selection_screen.dart` | ListView | No | None | HIGH | AuthProvider, DatabaseService | 2 `Colors.*` violations: `Colors.red`:146, `Colors.grey`:213. |

---

## 5. Widget Inventory

### Shared Widgets (`lib/shared/widgets/`)

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| ConfirmationDialog | `lib/shared/widgets/confirmation_dialog.dart` | ProjectListScreen, TrashScreen, multiple inline calls | Unknown (not audited in detail) | No -- already shared |
| EmptyStateWidget | `lib/shared/widgets/empty_state_widget.dart` | Various list screens | Unknown | No -- already shared |
| ContextualFeedbackOverlay | `lib/shared/widgets/contextual_feedback_overlay.dart` | Utility overlay | Unknown | No -- already shared |
| PermissionDialog | `lib/shared/widgets/permission_dialog.dart` | Photo/camera flows | Unknown | No -- already shared |
| SearchBarField | `lib/shared/widgets/search_bar_field.dart` | ProjectListScreen, QuantitiesScreen, GalleryScreen | Unknown | No -- already shared |
| StaleConfigWarning | `lib/shared/widgets/stale_config_warning.dart` | ScaffoldWithNavBar (shell) | Unknown | No -- already shared |
| VersionBanner | `lib/shared/widgets/version_banner.dart` | ScaffoldWithNavBar (shell) | Unknown | No -- already shared |
| ViewOnlyBanner | `lib/shared/widgets/view_only_banner.dart` | HomeScreen, EntriesListScreen | Unknown | No -- already shared |

### Entries Feature Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| EntryBasicsSection | `lib/features/entries/presentation/widgets/entry_basics_section.dart` | EntryEditorScreen | Partial (fontSize:16 inline) | No |
| EntryActivitiesSection | `lib/features/entries/presentation/widgets/entry_activities_section.dart` | EntryEditorScreen | Partial (fontSize:14,16 inline) | No |
| EntryContractorsSection | `lib/features/entries/presentation/widgets/entry_contractors_section.dart` | EntryEditorScreen | Partial (fontSize:12,13,16 inline) | No |
| EntryPhotosSection | `lib/features/entries/presentation/widgets/entry_photos_section.dart` | EntryEditorScreen | Partial (fontSize:12,16 inline) | No |
| EntryFormsSection | `lib/features/entries/presentation/widgets/entry_forms_section.dart` | EntryEditorScreen | Partial (fontSize:16 inline) | No |
| EntryQuantitiesSection | `lib/features/entries/presentation/widgets/entry_quantities_section.dart` | EntryEditorScreen | Poor (12 inline fontSize, 5 raw BorderRadius) | No |
| EntrySafetySection | `lib/features/entries/presentation/widgets/entry_safety_section.dart` | EntryEditorScreen | Partial (fontSize:16 inline) | No |
| EntryActionBar | `lib/features/entries/presentation/widgets/entry_action_bar.dart` | EntryEditorScreen, EntryReviewScreen | Partial (5 inline fontSize, 1 raw BR) | No |
| ContractorEditorWidget | `lib/features/entries/presentation/widgets/contractor_editor_widget.dart` | EntryEditorScreen, EntryContractorsSection | Poor (17 inline fontSize, 5 raw BR(4)) | No |
| ContractorSummaryWidget | `lib/features/entries/presentation/widgets/contractor_editor_widget.dart` | EntryReviewScreen | Poor (same file as above) | No |
| DraftEntryTile | `lib/features/entries/presentation/widgets/draft_entry_tile.dart` | DraftsListScreen | Partial (6 inline fontSize) | No |
| EntryFormCard | `lib/features/entries/presentation/widgets/entry_form_card.dart` | EntryFormsSection | Good (uses AppTheme.space*) | No |
| StatusBadge | `lib/features/entries/presentation/widgets/status_badge.dart` | EntriesListScreen, HomeScreen | Partial (fontSize:12 inline) | No |
| ReviewFieldRow | `lib/features/entries/presentation/widgets/review_field_row.dart` | EntryReviewScreen | Partial (4 inline fontSize) | No |
| ReviewMissingWarning | `lib/features/entries/presentation/widgets/review_missing_warning.dart` | EntryReviewScreen | Partial (fontSize:12,13 inline, BR(8)) | No |
| SimpleInfoRow | `lib/features/entries/presentation/widgets/simple_info_row.dart` | EntryReviewScreen | Partial (fontSize:12,14 inline) | No |
| FormSelectionDialog | `lib/features/entries/presentation/widgets/form_selection_dialog.dart` | EntryFormsSection | Partial (fontSize:10, BR(12)) | No |
| QuantityDialog | `lib/features/entries/presentation/widgets/quantity_dialog.dart` | EntryQuantitiesSection | Partial (fontSize:13) | No |
| PhotoDetailDialog | `lib/features/entries/presentation/widgets/photo_detail_dialog.dart` | EntryPhotosSection | Partial (fontSize:12, 5 raw BR(8)) | No |
| BidItemPickerSheet | `lib/features/entries/presentation/widgets/bid_item_picker_sheet.dart` | EntryQuantitiesSection | Partial (fontSize:11,13,18) | No |
| SubmittedBanner | `lib/features/entries/presentation/widgets/submitted_banner.dart` | EntryEditorScreen | Partial (fontSize:12,13) | No |

### Entries Report Widgets (`lib/features/entries/presentation/screens/report_widgets/`)

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| reportAddContractorSheet | `report_add_contractor_sheet.dart` | EntryContractorsSection | Partial (fontSize:16, bold section header pattern) | No |
| reportAddPersonnelTypeDialog | `report_add_personnel_type_dialog.dart` | EntryContractorsSection | Unknown | No |
| reportAddQuantityDialog | `report_add_quantity_dialog.dart` | EntryQuantitiesSection | Partial (fontSize:13) | No |
| reportDebugPdfActionsDialog | `report_debug_pdf_actions_dialog.dart` | EntryEditorScreen | Unknown | No |
| reportDeletePersonnelTypeDialog | `report_delete_personnel_type_dialog.dart` | EntryContractorsSection | Unknown | No |
| reportLocationEditDialog | `report_location_edit_dialog.dart` | EntryEditorScreen | Unknown | No |
| reportPdfActionsDialog | `report_pdf_actions_dialog.dart` | EntryEditorScreen | Unknown | No |
| reportPhotoDetailDialog | `report_photo_detail_dialog.dart` | EntryPhotosSection | Partial (fontSize:12, 5 raw BR(8)) | No |
| reportWeatherEditDialog | `report_weather_edit_dialog.dart` | EntryEditorScreen | Unknown | No |

### Dashboard Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| DashboardStatCard | `lib/features/dashboard/presentation/widgets/dashboard_stat_card.dart` | ProjectDashboardScreen | Partial (fontSize:11,22, `Colors.black.withValues`:54, `Colors.transparent`:61) | No |
| BudgetOverviewCard | `lib/features/dashboard/presentation/widgets/budget_overview_card.dart` | ProjectDashboardScreen | Partial (7 inline fontSize) | No |
| AlertItemRow | `lib/features/dashboard/presentation/widgets/alert_item_row.dart` | ProjectDashboardScreen | Partial (fontSize:12,13, 2 raw BR) | No |
| TrackedItemRow | `lib/features/dashboard/presentation/widgets/tracked_item_row.dart` | ProjectDashboardScreen | Partial (fontSize:11,13,16, `Colors.transparent`:46) | No |

### Projects Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| AddContractorDialog | `lib/features/projects/presentation/widgets/add_contractor_dialog.dart` | ProjectSetupScreen | Unknown | No |
| AddEquipmentDialog | `lib/features/projects/presentation/widgets/add_equipment_dialog.dart` | ProjectSetupScreen | Unknown | No |
| AddLocationDialog | `lib/features/projects/presentation/widgets/add_location_dialog.dart` | ProjectSetupScreen | Unknown | No |
| BidItemDialog | `lib/features/projects/presentation/widgets/bid_item_dialog.dart` | ProjectSetupScreen, PdfImportPreviewScreen, QuantitiesScreen | Unknown | No |
| PayItemSourceDialog | `lib/features/projects/presentation/widgets/pay_item_source_dialog.dart` | ProjectSetupScreen | Partial (fontSize:12,14, 3 raw BR(6,8)) | No |
| ProjectSwitcher | `lib/features/projects/presentation/widgets/project_switcher.dart` | ScaffoldWithNavBar shell | Partial (`Colors.grey[300]`:133, `Colors.grey`:226, raw BR(2,8)) | Yes -- drag handle bar |
| ProjectDetailsForm | `lib/features/projects/presentation/widgets/project_details_form.dart` | ProjectSetupScreen | Unknown | No |
| EquipmentChip | `lib/features/projects/presentation/widgets/equipment_chip.dart` | ProjectSetupScreen | Unknown | No |

### Quantities Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| BidItemCard | `lib/features/quantities/presentation/widgets/bid_item_card.dart` | QuantitiesScreen | Partial (6 inline fontSize) | No |
| BidItemDetailSheet | `lib/features/quantities/presentation/widgets/bid_item_detail_sheet.dart` | QuantitiesScreen | Partial (uses AppTheme.space*, but 12 inline fontSize) | No |
| QuantitySummaryHeader | `lib/features/quantities/presentation/widgets/quantity_summary_header.dart` | QuantitiesScreen | Partial (fontSize:12,22) | No |

### Settings Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| ClearCacheDialog | `lib/features/settings/presentation/widgets/clear_cache_dialog.dart` | SettingsScreen | Unknown | No |
| MemberDetailSheet | `lib/features/settings/presentation/widgets/member_detail_sheet.dart` | AdminDashboardScreen | Poor (`Colors.grey[300]`:53, `Colors.grey`:227,245, fontSize:13,18, BR(2,12)) | Yes -- drag handle bar |
| SectionHeader | `lib/features/settings/presentation/widgets/section_header.dart` | SettingsScreen, AdminDashboardScreen | Partial (fontSize:14) | Yes -- extract as shared section header |
| SignOutDialog | `lib/features/settings/presentation/widgets/sign_out_dialog.dart` | SettingsScreen | Unknown | No |
| SyncSection | `lib/features/settings/presentation/widgets/sync_section.dart` | SettingsScreen | Partial (fontSize:12) | No |
| ThemeSection | `lib/features/settings/presentation/widgets/theme_section.dart` | SettingsScreen | Unknown | No |

### Sync Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| SyncStatusIcon | `lib/features/sync/presentation/widgets/sync_status_icon.dart` | HomeScreen AppBar | Poor (`Colors.red`:34, `Colors.amber`:35, `Colors.green`:36) | No |
| DeletionNotificationBanner | `lib/features/sync/presentation/widgets/deletion_notification_banner.dart` | HomeScreen | Partial (fontSize:14) | No |

### Photos Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| PhotoThumbnail | `lib/features/photos/presentation/widgets/photo_thumbnail.dart` | GalleryScreen, EntryPhotosSection | Partial (3 raw BR(4,8), SizedBox(2)) | No |
| PhotoNameDialog | `lib/features/photos/presentation/widgets/photo_name_dialog.dart` | GalleryScreen, EntryPhotosSection | Partial (fontSize:12, BR(8)) | No |
| PhotoSourceDialog | `lib/features/photos/presentation/widgets/photo_source_dialog.dart` | GalleryScreen, EntryPhotosSection | Unknown | No |

### Forms Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| FormAccordion | `lib/features/forms/presentation/widgets/form_accordion.dart` | FormsListScreen | Poor (fontSize:11,12,15, BR(10,14,999), `Colors.transparent`:38) | No |
| FormThumbnail | `lib/features/forms/presentation/widgets/form_thumbnail.dart` | EntryFormsSection, FormsListScreen | Partial (fontSize:10, BR(4,8)) | No |
| HubHeaderContent | `lib/features/forms/presentation/widgets/hub_header_content.dart` | MdotHubScreen | Partial (fontSize:10, BR(10,12,999)) | No |
| HubProctorContent | `lib/features/forms/presentation/widgets/hub_proctor_content.dart` | MdotHubScreen | Poor (12 inline fontSize, 6 raw BR(10,12,999)) | No |
| HubQuickTestContent | `lib/features/forms/presentation/widgets/hub_quick_test_content.dart` | MdotHubScreen | Partial (fontSize:11, 4 raw BR(10,12)) | No |
| StatusPillBar | `lib/features/forms/presentation/widgets/status_pill_bar.dart` | FormsListScreen | Partial (fontSize:11, BR(20)) | No |
| SummaryTiles | `lib/features/forms/presentation/widgets/summary_tiles.dart` | MdotHubScreen | Partial (fontSize:11,15, BR(10)) | No |

### Auth Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| UserAttributionText | `lib/features/auth/presentation/widgets/user_attribution_text.dart` | EntriesListScreen | Unknown | No |

### PDF Widgets

| Widget | File | Used By | Tokenization | Extraction? |
|--------|------|---------|-------------|-------------|
| PdfImportProgressDialog | `lib/features/pdf/presentation/widgets/pdf_import_progress_dialog.dart` | PdfImportHelper flow | Partial (fontSize:13,14,16) | No |

---

## 6. Hardcoded Values Registry

### 6a. Colors (file:line -> current value -> should be)

#### Semantic Status Colors (replace with AppTheme.status*)

| File:Line | Current | Should Be |
|-----------|---------|-----------|
| `sync_status_icon.dart:34` | `Colors.red` | `AppTheme.statusError` |
| `sync_status_icon.dart:35` | `Colors.amber` | `AppTheme.statusWarning` |
| `sync_status_icon.dart:36` | `Colors.green` | `AppTheme.statusSuccess` |
| `sync_dashboard_screen.dart:161` | `Colors.red` | `AppTheme.statusError` |
| `sync_dashboard_screen.dart:163` | `Colors.amber` | `AppTheme.statusWarning` |
| `sync_dashboard_screen.dart:164` | `Colors.green` | `AppTheme.statusSuccess` |
| `sync_dashboard_screen.dart:384` | `Colors.orange` | `AppTheme.statusWarning` |
| `sync_dashboard_screen.dart:384` | `Colors.green` | `AppTheme.statusSuccess` |
| `conflict_viewer_screen.dart:188` | `Colors.green` | `AppTheme.statusSuccess` |
| `conflict_viewer_screen.dart:232` | `Colors.orange` | `AppTheme.statusWarning` |
| `project_selection_screen.dart:146` | `Colors.red` | `AppTheme.statusError` |
| `review_summary_screen.dart:91` | `Colors.red` | `AppTheme.statusError` |

#### Grey / Text Colors (replace with AppTheme.text*)

| File:Line | Current | Should Be |
|-----------|---------|-----------|
| `sync_dashboard_screen.dart:208` | `Colors.grey` | `AppTheme.textSecondary` |
| `sync_dashboard_screen.dart:395` | `Colors.grey` | `AppTheme.textSecondary` |
| `conflict_viewer_screen.dart:261` | `Colors.grey` | `AppTheme.textSecondary` |
| `conflict_viewer_screen.dart:277` | `Colors.grey.shade100` | `AppTheme.surfaceHighlight` |
| `project_selection_screen.dart:213` | `Colors.grey` | `AppTheme.textSecondary` |
| `admin_dashboard_screen.dart:90` | `Colors.grey` | `AppTheme.textSecondary` |
| `admin_dashboard_screen.dart:109` | `Colors.grey` | `AppTheme.textSecondary` |
| `admin_dashboard_screen.dart:265` | `Colors.grey` | `AppTheme.textSecondary` or `statusNeutral` (new) |
| `admin_dashboard_screen.dart:281` | `Colors.grey` | `AppTheme.textSecondary` or `statusNeutral` (new) |
| `member_detail_sheet.dart:53` | `Colors.grey[300]` | `AppTheme.surfaceHighlight` |
| `member_detail_sheet.dart:227` | `Colors.grey` | `AppTheme.textSecondary` |
| `member_detail_sheet.dart:245` | `Colors.grey` | `AppTheme.textSecondary` or `statusNeutral` (new) |
| `project_switcher.dart:133` | `Colors.grey[300]` | `AppTheme.surfaceHighlight` |
| `project_switcher.dart:226` | `Colors.grey` | `AppTheme.textSecondary` |

#### White on Primary (replace with AppTheme.textInverse)

| File:Line | Current | Should Be |
|-----------|---------|-----------|
| `settings_screen.dart:223` | `Colors.white` | `AppTheme.textInverse` |
| `admin_dashboard_screen.dart:148` | `Colors.white` | `AppTheme.textInverse` |
| `sync_dashboard_screen.dart:305` | `Colors.white` | `AppTheme.textInverse` |
| `review_summary_screen.dart:187` | `Colors.white` | `AppTheme.textInverse` |
| `profile_setup_screen.dart:201` | `Colors.white` | `AppTheme.textInverse` |
| `company_setup_screen.dart:277` | `Colors.white` | `AppTheme.textInverse` |
| `company_setup_screen.dart:387` | `Colors.white` | `AppTheme.textInverse` |
| `edit_profile_screen.dart:240` | `Colors.white` | `AppTheme.textInverse` |

#### Warning Chip Pattern (create new tokens: warningBackground, warningBorder)

| File:Line | Current | Should Be |
|-----------|---------|-----------|
| `project_dashboard_screen.dart:427` | `Colors.orange.shade800` | `AppTheme.statusWarning` (icon) |
| `project_dashboard_screen.dart:432` | `Colors.amber.shade50` | `AppTheme.warningBackground` (new) |
| `project_dashboard_screen.dart:433` | `Colors.amber.shade200` | `AppTheme.warningBorder` (new) |
| `quantities_screen.dart:173` | `Colors.orange.shade800` | `AppTheme.statusWarning` (icon) |
| `quantities_screen.dart:178` | `Colors.amber.shade50` | `AppTheme.warningBackground` (new) |
| `quantities_screen.dart:179` | `Colors.amber.shade200` | `AppTheme.warningBorder` (new) |

#### Photo Viewer Overlay (intentional but should be named)

| File:Line | Current | Context |
|-----------|---------|---------|
| `gallery_screen.dart:549` | `Colors.black` | Fullscreen photo viewer scaffold bg |
| `gallery_screen.dart:551` | `Colors.black` | AppBar bg |
| `gallery_screen.dart:552` | `Colors.white` | AppBar fg |
| `gallery_screen.dart:555` | `Colors.white` | Title text |
| `gallery_screen.dart:581` | `Colors.white54` | Loading indicator |
| `gallery_screen.dart:593` | `Colors.black87` | Info overlay bg |
| `gallery_screen.dart:601` | `Colors.white` | File name text |
| `gallery_screen.dart:609` | `Colors.white70` | Date text |
| `gallery_screen.dart:615` | `Colors.white70` | Note text |
| `gallery_screen.dart:623` | `Colors.white54` | Secondary icon |

These are intentional for a dark photo viewer context, but should use named tokens (e.g., `AppTheme.photoViewerBackground`, `AppTheme.photoViewerText`, etc.) or at minimum `AppTheme.textInverse`.

#### Acceptable Uses (keep as-is)

| File:Line | Value | Why Acceptable |
|-----------|-------|----------------|
| `home_screen.dart:774-776` | `Colors.transparent` | Calendar widget decoration overrides |
| `home_screen.dart:1954` | `Colors.transparent` | Same |
| `dashboard_stat_card.dart:61` | `Colors.transparent` | Button bg |
| `tracked_item_row.dart:46` | `Colors.transparent` | Row bg |
| `form_accordion.dart:38` | `Colors.transparent` | Unselected bg |
| `dashboard_screen.dart:148,150` | `Colors.transparent` | Card overrides |

#### Shadow Colors (consider new token or keep)

| File:Line | Value | Context |
|-----------|-------|---------|
| `dashboard_stat_card.dart:54` | `Colors.black.withValues(alpha: 0.15)` | Card shadow |
| `project_dashboard_screen.dart:477` | `Colors.black.withValues(alpha: 0.1)` | Section shadow |
| `entry_review_screen.dart:230` | `Colors.black.withValues(alpha: 0.1)` | Footer shadow |
| `drafts_list_screen.dart:219` | `Colors.black.withValues(alpha: 0.1)` | Footer shadow |
| `review_summary_screen.dart:167` | `Colors.black.withValues(alpha: 0.1)` | Footer shadow |

These 5 instances all use the same `Colors.black.withValues(alpha: 0.1)` pattern for shadows. Could become `AppTheme.shadowLight` or keep as-is.

### 6b. Typography (file:line -> current value -> should be)

Top duplicated patterns (highest-value fixes):

#### Pattern 1: Secondary Caption -- `TextStyle(fontSize: 12, color: AppTheme.textSecondary)` -> `textTheme.bodySmall`

| File:Line |
|-----------|
| `contractor_editor_widget.dart:110` |
| `contractor_editor_widget.dart:188` |
| `entry_action_bar.dart:214` |
| `entry_contractors_section.dart:130` |
| `entry_photos_section.dart:231` |
| `entries_list_screen.dart:574` |
| `home_screen.dart:869` |
| `home_screen.dart:1726` |
| `sync_section.dart:99` |
| `sync_section.dart:104` |
| `photo_detail_dialog.dart:168,182` |
| `report_photo_detail_dialog.dart:149,162` |

#### Pattern 2: Bold Section Header -- `TextStyle(fontWeight: FontWeight.bold, fontSize: 16)` -> `textTheme.titleMedium`

| File:Line |
|-----------|
| `entry_contractors_section.dart:123` |
| `entry_quantities_section.dart:179` |
| `entry_photos_section.dart:224` |
| `entry_forms_section.dart:155` |
| `entry_activities_section.dart:88` |
| `entry_basics_section.dart:74` |
| `entry_safety_section.dart:50` |
| `entry_editor_screen.dart:1186` |
| `home_screen.dart:1614` |
| `report_add_contractor_sheet.dart:33` |

#### Pattern 3: Small Badge Label -- `TextStyle(fontSize: 11, color: AppTheme.textSecondary)` -> `textTheme.labelSmall`

| File:Line |
|-----------|
| `contractor_editor_widget.dart:244` |
| `hub_quick_test_content.dart:225` |
| `hub_proctor_content.dart:417` |
| `entry_action_bar.dart:220` |
| `home_screen.dart:1399` |
| `dashboard_stat_card.dart:92` |
| `budget_overview_card.dart:118` |
| `tracked_item_row.dart:123` |

#### Pattern 4: Tertiary Hint -- `TextStyle(fontSize: 12, color: AppTheme.textTertiary)` -> `textTheme.bodySmall.copyWith(color: textTertiary)`

| File:Line |
|-----------|
| `photo_detail_dialog.dart:168` |
| `photo_detail_dialog.dart:182` |
| `report_photo_detail_dialog.dart:149` |
| `report_photo_detail_dialog.dart:162` |

### 6c. Dimensions -- SizedBox Spacing (highest-volume violations)

The raw values 8, 12, 16, 24 are the highest-volume violations. These directly map to existing tokens but are written as literals throughout.

| Raw Value | Token | Est. Instances |
|-----------|-------|---------------|
| 4 | `AppTheme.space1` | ~20 |
| 8 | `AppTheme.space2` | ~50+ |
| 12 | `AppTheme.space3` | ~40+ |
| 16 | `AppTheme.space4` | ~50+ |
| 24 | `AppTheme.space6` | ~20 |
| 32 | `AppTheme.space8` | ~10 |

Sub-token sizes (no existing token):
| Raw Value | Suggested Token | Instances |
|-----------|----------------|-----------|
| 2 | None (sub-pixel, intentional) | ~5 |
| 3 | None (sub-pixel) | ~2 |
| 6 | `space1_5` or `spaceXs` (new) | ~8 |
| 10 | None or `space2_5` (new) | ~5 |

### 6d. Border Radius (file:line -> current value -> should be)

| Value | Token Equivalent | Files (with lines) |
|-------|-----------------|-------------------|
| `BR.circular(4)` | `radiusXSmall` (NEW) | `photo_thumbnail.dart:237,259`, `contractor_editor_widget.dart:224,257,282,298,303`, `conflict_viewer_screen.dart:278`, `admin_dashboard_screen.dart:214,237`, `project_setup_screen.dart:415`, `pdf_import_preview_screen.dart:423`, `alert_item_row.dart:58`, `form_thumbnail.dart:95,112`, `entry_quantities_section.dart:369` |
| `BR.circular(6)` | `radiusCompact` (NEW) | `pay_item_source_dialog.dart:106`, `project_list_screen.dart:529` |
| `BR.circular(8)` | `AppTheme.radiusSmall` | `photo_thumbnail.dart:188`, `project_switcher.dart:32`, `photo_name_dialog.dart:235`, `pay_item_source_dialog.dart:93,98`, `review_missing_warning.dart:25`, `photo_detail_dialog.dart:101,103,107,121,154`, `entry_quantities_section.dart:254,354,359`, `entry_action_bar.dart:192`, `alert_item_row.dart:28`, `form_thumbnail.dart:36`, `project_list_screen.dart:590`, `entries_list_screen.dart:544`, `entry_editor_screen.dart:661`, `report_photo_detail_dialog.dart:83,85,89,102,136` |
| `BR.circular(10)` | `radiusCompact` (NEW) or none | `summary_tiles.dart:26`, `project_list_screen.dart:187`, `hub_quick_test_content.dart:49,70,219`, `hub_proctor_content.dart:63,234,355`, `hub_header_content.dart:88,92`, `form_accordion.dart:130` |
| `BR.circular(12)` | `AppTheme.radiusMedium` | `todos_screen.dart:131,579`, `member_detail_sheet.dart:252`, `settings_screen.dart:218`, `admin_dashboard_screen.dart:143`, `form_selection_dialog.dart:51`, `project_list_screen.dart:280,423`, `hub_quick_test_content.dart:180`, `hub_proctor_content.dart:83,301`, `hub_header_content.dart:57`, `entries_list_screen.dart:398,408`, `entry_editor_screen.dart:691,697` |
| `BR.circular(14)` | None (gap) | `form_accordion.dart:45,53` |
| `BR.circular(20)` | None (between radiusLarge/XLarge) | `status_pill_bar.dart:60` |
| `BR.circular(999)` | `AppTheme.radiusFull` | `hub_proctor_content.dart:113`, `hub_header_content.dart:108`, `form_accordion.dart:163` |
| `BR.circular(2)` | None (drag handle) | `member_detail_sheet.dart:54`, `project_switcher.dart:134` |

---

## 7. Dependency Graph

### 7a. Provider -> Screen Consumption Map

| Provider | Screen Count | Screens |
|----------|-------------|---------|
| **AuthProvider** | 23 | All auth screens (10), SettingsScreen, EditProfileScreen, AdminDashboardScreen, HomeScreen, ProjectListScreen, EntriesListScreen, EntryEditorScreen, ProjectSetupScreen, QuantitiesScreen, FormsListScreen, FormViewerScreen, MdotHubScreen, TodosScreen, ProjectSelectionScreen |
| **ProjectProvider** | 13 | ProjectDashboardScreen, HomeScreen, ProjectListScreen, ProjectSetupScreen, EntriesListScreen, EntryEditorScreen, QuantitiesScreen, QuantityCalculatorScreen, FormsListScreen, FormViewerScreen, MdotHubScreen, GalleryScreen, ProjectSwitcher |
| **LocationProvider** | 7 | ProjectDashboardScreen, ProjectSetupScreen, EntryEditorScreen, EntriesListScreen, DraftsListScreen, EntryReviewScreen, ReviewSummaryScreen |
| **BidItemProvider** | 6 | ProjectDashboardScreen, ProjectSetupScreen, QuantitiesScreen, EntryEditorScreen, HomeScreen (5 unique screens + ProjectSwitcher) |
| **DailyEntryProvider** | 5 | ProjectDashboardScreen, HomeScreen, EntriesListScreen, EntryEditorScreen, DraftsListScreen |
| **ContractorProvider** | 5 | ProjectDashboardScreen, ProjectSetupScreen, EntryEditorScreen, HomeScreen (4 unique screens) |
| **EntryQuantityProvider** | 3 | ProjectDashboardScreen, QuantitiesScreen, EntryEditorScreen |
| **PersonnelTypeProvider** | 3 | PersonnelTypesScreen, EntryEditorScreen, HomeScreen |
| **EquipmentProvider** | 3 | ProjectSetupScreen, EntryEditorScreen, HomeScreen |
| **PhotoProvider** | 2 | EntryEditorScreen, HomeScreen |
| **SyncProvider** | 3 | ScaffoldWithNavBar (shell), SyncDashboardScreen, SyncStatusIcon |
| **GalleryProvider** | 1 | GalleryScreen |
| **InspectorFormProvider** | 4 | FormsListScreen, FormViewerScreen, MdotHubScreen, EntryEditorScreen |
| **TodoProvider** | 1 | TodosScreen |
| **CalendarFormatProvider** | 1 | HomeScreen |
| **AdminProvider** | 2 | AdminDashboardScreen, MemberDetailSheet |
| **ThemeProvider** | 1 | ThemeSection (SettingsScreen) |
| **ProjectSettingsProvider** | 1 | SettingsScreen |
| **AppConfigProvider** | 3 | SettingsScreen, UpdateRequiredScreen, ScaffoldWithNavBar |
| **CalculatorProvider** | 2 | CalculatorScreen, QuantityCalculatorScreen |

### 7b. Non-Provider Service Access via context.read<>

| Service | Screens |
|---------|---------|
| `DatabaseService` | EntryEditorScreen, ProjectListScreen, SettingsScreen, TrashScreen, SyncDashboardScreen, ConflictViewerScreen, ProjectSelectionScreen |
| `AuthService` | CompanySetupScreen, PendingApprovalScreen |
| `FormPdfService` | FormViewerScreen, MdotHubScreen |
| `SyncRegistry` | ConflictViewerScreen |

### 7c. Cross-Feature Widget Imports

| Source Feature | Imports From | What |
|---------------|-------------|------|
| entries | projects | ProjectProvider |
| entries | locations | LocationProvider |
| entries | contractors | ContractorProvider, EquipmentProvider, PersonnelTypeProvider |
| entries | quantities | EntryQuantityProvider, BidItemProvider |
| entries | photos | PhotoProvider |
| entries | forms | InspectorFormProvider |
| entries | auth | AuthProvider, UserAttributionText |
| entries | pdf | PdfService |
| dashboard | projects, entries, locations, quantities, contractors | Multiple providers |
| projects | auth, locations, contractors, quantities | Multiple providers |
| quantities | projects, auth, calculator | Multiple providers |
| gallery | projects | ProjectProvider |
| forms | projects, auth | ProjectProvider, AuthProvider |
| settings | auth, sync, projects | AuthProvider, SyncProvider, ProjectSettingsProvider |
| sync | auth | AuthProvider |
| todos | projects, auth | ProjectProvider, AuthProvider |

### 7d. EntryEditorScreen Dependency Hub Analysis

`EntryEditorScreen` is the most complex screen in the app:
- **11 providers** read via `context.read<>`: DailyEntryProvider, LocationProvider, ProjectProvider, ContractorProvider, EquipmentProvider, EntryQuantityProvider, PhotoProvider, PersonnelTypeProvider, InspectorFormProvider, BidItemProvider, AuthProvider
- **1 service** read: DatabaseService
- **10+ child widget classes**: EntryBasicsSection, EntryActivitiesSection, EntryContractorsSection, EntryPhotosSection, EntryFormsSection, EntryQuantitiesSection, EntrySafetySection, EntryActionBar, ContractorEditorWidget, SubmittedBanner
- **7 report dialog/sheet functions**: reportAddContractorSheet, reportAddPersonnelTypeDialog, reportAddQuantityDialog, reportDebugPdfActionsDialog, reportDeletePersonnelTypeDialog, reportLocationEditDialog, reportPdfActionsDialog, reportPhotoDetailDialog, reportWeatherEditDialog

This is the highest-risk screen for any refactor. Changes to its children or providers can have cascading effects.

---

## 8. Modal Surface Registry

### Bottom Sheets (8 total)

| # | Location (File:Line) | What It Shows | SafeArea? | Issues |
|---|---------------------|---------------|-----------|--------|
| 1 | `admin_dashboard_screen.dart:367` | MemberDetailSheet | NO | Uses `viewInsets.bottom` instead of `viewPadding.bottom` :40 |
| 2 | `bid_item_detail_sheet.dart:17` | BidItemDetailSheet (DraggableScrollableSheet) | Yes (via DSS) | None known |
| 3 | `project_switcher.dart:69` | _ProjectSwitcherSheet | NO | Uses `viewInsets.bottom` instead of `viewPadding.bottom` :120 |
| 4 | `photo_source_dialog.dart:25` | PhotoSourceDialog | Unknown | Needs audit |
| 5 | `gallery_screen.dart:304` | Photo options | Unknown | Needs audit |
| 6 | `home_screen.dart:1604` | Contractor picker | NO | No SafeArea, bottom cutoff bug confirmed |
| 7 | `bid_item_picker_sheet.dart:16` | BidItem picker (DraggableScrollableSheet) | Yes (via DSS) | None known |
| 8 | `report_add_contractor_sheet.dart:16` | Add contractor to entry | YES | `SafeArea` wraps content :19 |

### Dialogs (~30 total)

| # | Location (File:Line) | What It Shows | Issues |
|---|---------------------|---------------|--------|
| 1 | `confirmation_dialog.dart` (shared) | 3 dialog variants | None known |
| 2 | `permission_dialog.dart` (shared) | Storage permission | None known |
| 3 | `todos_screen.dart:345,361,381,407` | Create/edit/delete todo | None known |
| 4 | `admin_dashboard_screen.dart:304,334` | Approve/reject user | None known |
| 5 | `personnel_types_screen.dart:152,249,334` | Add/edit/delete type | None known |
| 6 | `settings_screen.dart:41,83` | App version, theme | None known |
| 7 | `trash_screen.dart:283,324` | Restore/purge | None known |
| 8 | `clear_cache_dialog.dart:11` | Clear cache | None known |
| 9 | `member_detail_sheet.dart:317` | Role change confirm | None known |
| 10 | `sign_out_dialog.dart:12` | Sign out confirm | None known |
| 11 | `project_list_screen.dart:474,566` | Delete/archive project | None known |
| 12 | `add_contractor_dialog.dart:17` | Add contractor form | None known |
| 13 | `add_equipment_dialog.dart:17` | Add equipment form | None known |
| 14 | `add_location_dialog.dart:17` | Add location form | None known |
| 15 | `bid_item_dialog.dart:23` | Add/edit bid item | None known |
| 16 | `pay_item_source_dialog.dart:18` | Pay item source | 3 raw BorderRadius |
| 17 | `photo_name_dialog.dart:66` | Name photo | 1 raw BR, 1 fontSize |
| 18 | `pdf_service.dart:322` | PDF password prompt | Unknown |
| 19 | `pdf_import_helper.dart:119` | Import error | Unknown |
| 20 | `pdf_import_preview_screen.dart:254` | Edit bid item | Unknown |
| 21 | `pdf_import_progress_manager.dart:37` | Import progress | 3 inline fontSize |
| 22 | `form_viewer_screen.dart:223` | Discard changes | Unknown |
| 23 | `photo_detail_dialog.dart` | Photo metadata | 2 fontSize, 5 raw BR |
| 24 | `form_selection_dialog.dart` | Select form | 1 fontSize, 1 raw BR |
| 25 | `quantity_dialog.dart` | Quantity entry | 1 fontSize |
| 26 | `report_photo_detail_dialog.dart` | Report photo metadata | 2 fontSize, 5 raw BR |
| 27 | `report_add_quantity_dialog.dart` | Add quantity to report | 1 fontSize |
| 28 | `report_add_personnel_type_dialog.dart` | Add personnel type | Unknown |
| 29 | `report_delete_personnel_type_dialog.dart` | Delete personnel type | Unknown |
| 30 | `report_location_edit_dialog.dart` | Edit location | Unknown |

### DraggableScrollableSheets (2 total)

| # | Location (File:Line) | Inside |
|---|---------------------|--------|
| 1 | `bid_item_detail_sheet.dart:37` | Bottom sheet |
| 2 | `bid_item_picker_sheet.dart:29` | Bottom sheet |

---

## 9. Confirmed Bugs

### Bottom Cutoff / SafeArea Bugs (6 confirmed)

| # | File:Line | Bug | Root Cause | Fix |
|---|-----------|-----|-----------|-----|
| 1 | `pdf_import_preview_screen.dart:193-195` | Bottom bar content cut off by system nav bar | `bottomNavigationBar` Container with `EdgeInsets.all(16)`, no SafeArea wrapping | Wrap bottom bar content in `SafeArea(child: ...)` |
| 2 | `mp_import_preview_screen.dart:72` | Same as above | Same pattern -- bottomNavigationBar without SafeArea | Wrap bottom bar content in `SafeArea(child: ...)` |
| 3 | `settings_screen.dart:339` | Content behind nav bar | `SizedBox(height: 32)` at bottom of ListView is insufficient under system nav bar on devices with gesture nav | Replace with `SizedBox(height: MediaQuery.of(context).padding.bottom + 32)` or use SafeArea |
| 4 | `home_screen.dart:1604` | Contractor picker sheet content cut off at bottom | `showModalBottomSheet` with Container padding but no SafeArea | Add `SafeArea` wrapper inside bottom sheet builder |
| 5 | `project_switcher.dart:116-120` | Sheet content behind system nav on gesture-nav devices | Uses `MediaQuery.of(context).viewInsets.bottom` which only accounts for keyboard, not system nav bar | Change to `MediaQuery.of(context).viewPadding.bottom` |
| 6 | `member_detail_sheet.dart:36-40` | Same as above | Uses `viewInsets.bottom` instead of `viewPadding.bottom` | Change to `viewPadding.bottom` |

### Other Layout Issues

- **Only auth screens use SafeArea on body**: 15 SafeArea uses found across all screens -- 10 are auth screens, 1 is gallery, 1 is edit profile, 3 are footer wraps (entry review, review summary, drafts list). The remaining 23+ screens have no SafeArea protection.
- **SliverAppBar usage**: Only 3 screens use SliverAppBar (ProjectDashboardScreen, HomeScreen, and one other). The rest use standard AppBar. This is consistent but may want to be revisited for scroll-to-collapse patterns.

---

## 10. Extraction Candidates

### 10a. Widgets That Should Be Shared (duplicate implementations)

| Candidate | Where Duplicated | Current Implementations | Priority |
|-----------|-----------------|------------------------|----------|
| **Budget Discrepancy Chip** | Dashboard + Quantities | `project_dashboard_screen.dart:427-433` and `quantities_screen.dart:173-179` -- identical `Colors.orange.shade800` icon + `Colors.amber.shade50` bg + `Colors.amber.shade200` border pattern | HIGH |
| **Drag Handle Bar** | ProjectSwitcher + MemberDetailSheet | `project_switcher.dart:128-137` (Container, 40x4, grey[300], BR(2)) and `member_detail_sheet.dart:47-56` (Container, 40x4, grey[300], BR(2)) -- nearly identical but independently coded | HIGH |
| **Section Header** | 3+ implementations | `section_header.dart` (settings), inline in entry sections (`TextStyle(fontWeight: FontWeight.bold, fontSize: 16)` pattern appears in 10+ places), and dashboard section titles | HIGH |
| **Error State Widget** | 3+ screens | Duplicated empty/error state pattern with icon + message + optional action button in entries, forms, and projects list screens | MEDIUM |
| **Status Badge / Active Chip** | Multiple features | `status_badge.dart` in entries, but similar concepts duplicated in admin dashboard role badges (:214-242), form status pills, and entry status indicators | MEDIUM |
| **Shadow Decoration** | 5 files | `Colors.black.withValues(alpha: 0.1)` box shadow pattern in `dashboard_stat_card.dart:54`, `project_dashboard_screen.dart:477`, `entry_review_screen.dart:230`, `drafts_list_screen.dart:219`, `review_summary_screen.dart:167` | LOW |

### 10b. Text Style Patterns That Should Be Named

| Pattern | Current Code | Suggested Approach | Instances |
|---------|-------------|-------------------|-----------|
| Secondary caption | `TextStyle(fontSize: 12, color: AppTheme.textSecondary)` | Use `textTheme.bodySmall` | 14+ |
| Bold section header | `TextStyle(fontWeight: FontWeight.bold, fontSize: 16)` | Use `textTheme.titleMedium` | 10+ |
| Small badge label | `TextStyle(fontSize: 11, color: AppTheme.textSecondary)` | Use `textTheme.labelSmall.copyWith(color: textSecondary)` | 8+ |
| Tertiary hint | `TextStyle(fontSize: 12, color: AppTheme.textTertiary)` | Use `textTheme.bodySmall.copyWith(color: textTertiary)` | 4+ |
| Bold emphasis 12sp | `TextStyle(fontSize: 12, fontWeight: FontWeight.w800)` | Use `textTheme.labelMedium` | 4 (hub_proctor_content) |

---

## 11. Reference Implementations

These files are already well-tokenized and should serve as templates during the refactor:

### Gold Standard (auth screens)

| File | Why It Is Good |
|------|---------------|
| `lib/features/auth/presentation/screens/login_screen.dart` | Uses `AppTheme.space*` for all spacing, `textTheme.*` for text styles, `AppTheme.*` for colors, `SafeArea` on body. Only violation: `Colors.white` on one button. |
| `lib/features/auth/presentation/screens/pending_approval_screen.dart` | Uses `AppTheme.touchTargetComfortable`, `AppTheme.space*` throughout. Zero violations. |
| `lib/features/auth/presentation/screens/account_status_screen.dart` | Fully tokenized. Zero violations. |

### Well-Tokenized Feature Files

| File | Why It Is Good |
|------|---------------|
| `lib/features/entries/presentation/widgets/entry_form_card.dart` | Uses `AppTheme.space*` throughout for padding and spacing. |
| `lib/features/quantities/presentation/widgets/bid_item_detail_sheet.dart` | Uses `AppTheme.space*` throughout. Only violation: inline fontSize values (typography gap applies globally). |
| `lib/features/toolbox/presentation/screens/toolbox_home_screen.dart` | Fully tokenized. No providers. Clean. |
| `lib/features/todos/presentation/screens/todos_screen.dart` | Well tokenized except 2 raw BorderRadius(12). |
| `lib/features/calculator/presentation/screens/calculator_screen.dart` | Fully tokenized. |

---

## 12. Risk Assessment

### Highest Risk (refactor last)

| Screen | Risk Level | Why |
|--------|-----------|-----|
| **EntryEditorScreen** | CRITICAL | 11 providers, 10+ child widgets, 7 report dialogs. Dependency hub for the entire app. Any change cascades to entries, contractors, quantities, photos, forms. |
| **HomeScreen** | CRITICAL | 11 providers, 2000+ lines, largest screen. Calendar integration, entry cards, contractor picker sheet. Bottom cutoff bug to fix. |
| **ProjectDashboardScreen** | HIGH | 6 providers, custom stat cards, budget overview, cross-feature data aggregation. Warning chip pattern duplicated with quantities. |
| **ProjectSetupScreen** | HIGH | 6 providers, 5 different dialogs launched. Complex form with location/contractor/equipment/bid item management. |

### Medium Risk

| Screen | Risk Level | Why |
|--------|-----------|-----|
| **EntriesListScreen** | MEDIUM | 4 providers, complex list with status badges, date grouping, user attribution. |
| **QuantitiesScreen** | MEDIUM | 4 providers, warning chip to extract, bid item cards. |
| **AdminDashboardScreen** | MEDIUM | 2 providers, but heavy `Colors.*` violations and raw dimensions. |
| **SyncDashboardScreen** | MEDIUM | Worst offender for hardcoded values but only 2 providers. Isolated feature. |
| **SettingsScreen** | MEDIUM | 4 providers, multiple dialogs, bottom cutoff bug. |

### Lowest Risk (refactor first)

| Screen | Risk Level | Why |
|--------|-----------|-----|
| **Auth screens (10)** | VERY LOW | Already well-tokenized. Only need `Colors.white` -> `AppTheme.textInverse` fixes. Self-contained, no cross-feature deps. |
| **ToolboxHomeScreen** | VERY LOW | Zero providers, zero violations. Already done. |
| **CalculatorScreen** | VERY LOW | 1 provider, fully tokenized. Already done. |
| **TodosScreen** | LOW | 1 primary provider, 2 minor BR violations. Isolated feature. |
| **FormsListScreen** | LOW | 1 fontSize violation. Clean. |
| **TrashScreen** | LOW | 1 provider (DatabaseService), 6 fontSize violations. No cross-feature impact. |
| **EditProfileScreen** | LOW | 1 Colors.white violation. SafeArea already present. |
| **ConflictViewerScreen** | LOW | Isolated sync feature, 4 Colors + 3 fontSize violations. |
| **ProjectSelectionScreen** | LOW | Isolated sync feature, 2 Colors violations. |
| **SyncStatusIcon** | LOW | 3 Colors violations, trivial fix. Single widget used in HomeScreen. |
| **PersonnelTypesScreen** | LOW | 1 fontSize violation. Simple screen. |
| **GalleryScreen** | LOW-MEDIUM | Photo viewer Colors are intentional. 1 provider. Isolated. |
| **DraftsListScreen** | LOW | 2 fontSize, 1 shadow. SafeArea already present on footer. |
| **ProjectListScreen** | MEDIUM-LOW | 15 fontSize, 5 BR violations but only 2 providers. No Colors violations. |

### Suggested Refactor Order

**Phase 1 -- Foundation (do first)**
1. Add missing tokens to `AppTheme` (radius, icon size, spacing re-exports, animation re-exports, warning chip colors, statusNeutral, photo viewer colors)
2. Fix 6 confirmed bottom-cutoff bugs (mechanical fixes)
3. Extract shared `DragHandleBar` widget
4. Extract shared `BudgetDiscrepancyChip` widget
5. Extract shared `SectionHeader` widget

**Phase 2 -- Quick Wins (lowest risk, build confidence)**
6. Fix `Colors.white` -> `AppTheme.textInverse` across all auth screens (8 instances)
7. Fix `SyncStatusIcon` (3 Colors -> 3 status tokens)
8. Fix `ProjectSelectionScreen` (2 Colors violations)
9. Fix `ConflictViewerScreen` (4 Colors + 3 fontSize)
10. Fix `PersonnelTypesScreen` (1 fontSize)
11. Fix `FormsListScreen` (1 fontSize)
12. Fix `EditProfileScreen` (1 Colors.white)

**Phase 3 -- Isolated Features (medium risk, no cross-feature impact)**
13. Refactor `SyncDashboardScreen` (worst offender, but isolated)
14. Refactor `AdminDashboardScreen` (heavy violations, but isolated)
15. Refactor `TrashScreen` (6 fontSize)
16. Refactor `GalleryScreen` (photo viewer colors)
17. Refactor `DraftsListScreen`, `EntryReviewScreen`, `ReviewSummaryScreen`
18. Refactor `SettingsScreen` + settings widgets
19. Refactor `MemberDetailSheet`
20. Refactor `ProjectSwitcher`

**Phase 4 -- Forms Feature (medium risk, self-contained)**
21. Refactor `FormAccordion`, `StatusPillBar`, `SummaryTiles`
22. Refactor `HubProctorContent` (worst forms widget)
23. Refactor `HubHeaderContent`, `HubQuickTestContent`
24. Refactor `FormThumbnail`

**Phase 5 -- PDF Feature (medium risk)**
25. Refactor `PdfImportPreviewScreen` (15 fontSize, bottom cutoff fix)
26. Refactor `MpImportPreviewScreen` (4 fontSize, bottom cutoff fix)
27. Refactor `PdfImportProgressDialog`

**Phase 6 -- Quantities Feature**
28. Refactor `BidItemCard`, `BidItemDetailSheet`, `QuantitySummaryHeader`
29. Refactor `QuantitiesScreen` (use extracted BudgetDiscrepancyChip)

**Phase 7 -- Projects Feature**
30. Refactor `ProjectListScreen` (15 fontSize, 5 BR -- high volume, low risk)
31. Refactor `PayItemSourceDialog`
32. Refactor `ProjectDetailsForm`, equipment/contractor/location dialogs

**Phase 8 -- Entry Widgets (high volume, medium risk)**
33. Refactor `ContractorEditorWidget` (17 fontSize, 5 BR -- highest violation count of any widget)
34. Refactor `EntryActionBar`, `StatusBadge`, `DraftEntryTile`
35. Refactor `EntryBasicsSection`, `EntryActivitiesSection`, `EntrySafetySection`
36. Refactor `EntryContractorsSection`, `EntryPhotosSection`, `EntryFormsSection`
37. Refactor `EntryQuantitiesSection` (12 fontSize, 5 BR)
38. Refactor review widgets: `ReviewFieldRow`, `ReviewMissingWarning`, `SimpleInfoRow`
39. Refactor all `report_*` dialog/sheet widgets
40. Refactor `PhotoDetailDialog`, `QuantityDialog`, `FormSelectionDialog`
41. Refactor `BidItemPickerSheet`

**Phase 9 -- Entries Screens (high risk, do last)**
42. Refactor `EntriesListScreen` (15 fontSize, 3 BR)
43. Refactor `ProjectDashboardScreen` (24 fontSize, Colors violations)
44. Refactor `ProjectSetupScreen`
45. Refactor `EntryEditorScreen` (dependency hub -- refactor AFTER all child widgets are done)
46. Refactor `HomeScreen` (2000+ lines, 35+ fontSize, bottom cutoff fix -- refactor LAST)

---

## Appendix: Quick Statistics Summary

| Metric | Count |
|--------|-------|
| Total screen classes | 38 |
| Total presentation widgets | 80+ |
| Total modal surfaces | ~40 |
| Total routes | 35 |
| Total providers | 20 |
| Color tokens (existing) | 51 |
| Spacing tokens (existing, via AppTheme) | 8 |
| Radius tokens (existing) | 5 |
| Elevation tokens | 4 |
| Touch target tokens | 3 |
| Animation tokens (via AppTheme) | 5 |
| Text theme slots (defined) | 15 |
| Text theme actual usage (files) | 17 files, 33 uses |
| Inline TextStyle usage | 179+ instances, 58+ files |
| Raw Colors.* violations | ~55 instances, ~25 files |
| Raw SizedBox spacing violations | 200+ instances, 60+ files |
| Raw EdgeInsets violations | 179 instances, 58 files |
| Raw BorderRadius violations | 70+ instances, 35+ files |
| Raw icon size violations | 150 instances, 55 files |
| AppTheme.* references (adoption) | 1,330+ |
| Files using AppTheme.* colors | 91 |
| Files using AppTheme.space* | 31 |
| Features with zero Colors.* violations | calculator, locations, photos, weather, todos, toolbox |
| Confirmed layout/cutoff bugs | 6 |
| Widget extraction candidates | 6 patterns |
| Cross-feature import relationships | 28 |
