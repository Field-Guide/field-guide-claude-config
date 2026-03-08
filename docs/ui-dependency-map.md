# UI Dependency Map -- Field Guide App

Generated: 2026-03-06
Source: CodeMunch index `local/Field_Guide_App`

---

## 1. Screen Inventory Table

### Auth Screens (Full-screen, outside shell -- no bottom nav)

| # | Screen Class | File | Type | Providers Used | Key Widgets |
|---|-------------|------|------|---------------|-------------|
| 1 | `LoginScreen` | `lib/features/auth/presentation/screens/login_screen.dart` | StatefulWidget | AuthProvider (Consumer + read) | -- |
| 2 | `RegisterScreen` | `lib/features/auth/presentation/screens/register_screen.dart` | StatefulWidget | AuthProvider (Consumer + read) | -- |
| 3 | `ForgotPasswordScreen` | `lib/features/auth/presentation/screens/forgot_password_screen.dart` | StatefulWidget | AuthProvider (Consumer + read) | -- |
| 4 | `OtpVerificationScreen` | `lib/features/auth/presentation/screens/otp_verification_screen.dart` | StatefulWidget | AuthProvider (Consumer x2 + read) | -- |
| 5 | `UpdatePasswordScreen` | `lib/features/auth/presentation/screens/update_password_screen.dart` | StatefulWidget | AuthProvider (read) | -- |
| 6 | `UpdateRequiredScreen` | `lib/features/auth/presentation/screens/update_required_screen.dart` | StatelessWidget | AppConfigProvider (watch) | -- |
| 7 | `ProfileSetupScreen` | `lib/features/auth/presentation/screens/profile_setup_screen.dart` | StatefulWidget | AuthProvider (read) | -- |
| 8 | `CompanySetupScreen` | `lib/features/auth/presentation/screens/company_setup_screen.dart` | StatefulWidget | AuthProvider, AuthService (read) | -- |
| 9 | `PendingApprovalScreen` | `lib/features/auth/presentation/screens/pending_approval_screen.dart` | StatefulWidget | AuthProvider, AuthService (read) | -- |
| 10 | `AccountStatusScreen` | `lib/features/auth/presentation/screens/account_status_screen.dart` | StatelessWidget | AuthProvider (read) | -- |

### Shell Route Screens (Bottom nav bar)

| # | Screen Class | Route | File | Providers Used | Key Widgets |
|---|-------------|-------|------|---------------|-------------|
| 11 | `ProjectDashboardScreen` | `/` | `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart` | ProjectProvider (Consumer + read), DailyEntryProvider (Consumer + read), LocationProvider (read), BidItemProvider (read), ContractorProvider (read), EntryQuantityProvider (read) | DashboardStatCard, BudgetOverviewCard, AlertItemRow, TrackedItemRow |
| 12 | `HomeScreen` | `/calendar` | `lib/features/entries/presentation/screens/home_screen.dart` | ProjectProvider (Consumer), DailyEntryProvider (Consumer), CalendarFormatProvider (watch), LocationProvider, ContractorProvider, EquipmentProvider, PhotoProvider, AuthProvider, BidItemProvider, PersonnelTypeProvider, EntryQuantityProvider | SyncStatusIcon, DeletionNotificationBanner, ViewOnlyBanner |
| 13 | `ProjectListScreen` | `/projects` | `lib/features/projects/presentation/screens/project_list_screen.dart` | ProjectProvider (Consumer + read), AuthProvider (read), DatabaseService (read) | SearchBarField, ConfirmationDialog |
| 14 | `SettingsScreen` | `/settings` | `lib/features/settings/presentation/screens/settings_screen.dart` | AuthProvider (Consumer x2 + read), ProjectSettingsProvider (Consumer), AppConfigProvider (Consumer x2), DatabaseService (read) | SyncSection, ThemeSection, SignOutDialog, ClearCacheDialog, SectionHeader |

### Full-screen Routes (Outside shell)

| # | Screen Class | Route | File | Providers Used | Key Widgets |
|---|-------------|-------|------|---------------|-------------|
| 15 | `EntryEditorScreen` | `/entry/:projectId/:date` and `/report/:entryId` | `lib/features/entries/presentation/screens/entry_editor_screen.dart` | DailyEntryProvider, LocationProvider, ProjectProvider, ContractorProvider, EquipmentProvider, EntryQuantityProvider, PhotoProvider, PersonnelTypeProvider, InspectorFormProvider, BidItemProvider, DatabaseService, AuthProvider (all read) | EntryBasicsSection, EntryActivitiesSection, EntryContractorsSection, EntryPhotosSection, EntryFormsSection, EntryQuantitiesSection, EntrySafetySection, EntryActionBar, _EditableSafetyCard, ContractorEditorWidget |
| 16 | `EntriesListScreen` | `/entries` | `lib/features/entries/presentation/screens/entries_list_screen.dart` | ProjectProvider (read), DailyEntryProvider (read), LocationProvider (read), AuthProvider (read) | StatusBadge, UserAttributionText |
| 17 | `DraftsListScreen` | `/drafts/:projectId` | `lib/features/entries/presentation/screens/drafts_list_screen.dart` | DailyEntryProvider (read), LocationProvider (watch) | DraftEntryTile |
| 18 | `EntryReviewScreen` | `/review` | `lib/features/entries/presentation/screens/entry_review_screen.dart` | LocationProvider (watch) | ReviewFieldRow, ReviewMissingWarning, SimpleInfoRow, ContractorSummaryWidget, EntryStatusSection |
| 19 | `ReviewSummaryScreen` | `/review-summary` | `lib/features/entries/presentation/screens/review_summary_screen.dart` | LocationProvider (watch) | -- |
| 20 | `ProjectSetupScreen` | `/project/new` and `/project/:projectId/edit` | `lib/features/projects/presentation/screens/project_setup_screen.dart` | LocationProvider (Consumer + read), ContractorProvider (Consumer + read), EquipmentProvider (read), BidItemProvider (Consumer + read), ProjectProvider (read), AuthProvider (read) | ProjectDetailsForm, AddContractorDialog, AddEquipmentDialog, AddLocationDialog, BidItemDialog, PayItemSourceDialog, EquipmentChip |
| 21 | `QuantitiesScreen` | `/quantities` | `lib/features/quantities/presentation/screens/quantities_screen.dart` | ProjectProvider (Consumer + read), BidItemProvider (read), EntryQuantityProvider (read), AuthProvider (read) | BidItemCard, QuantitySummaryHeader, BidItemDetailSheet, BidItemDialog |
| 22 | `QuantityCalculatorScreen` | `/quantity-calculator/:entryId` | `lib/features/quantities/presentation/screens/quantity_calculator_screen.dart` | CalculatorProvider (Consumer + read), ProjectProvider (read) | -- |
| 23 | `CalculatorScreen` | `/calculator` | `lib/features/calculator/presentation/screens/calculator_screen.dart` | CalculatorProvider (Consumer x2) | _HmaCalculator, _ConcreteCalculator, _HistoryTile |
| 24 | `GalleryScreen` | `/gallery` | `lib/features/gallery/presentation/screens/gallery_screen.dart` | GalleryProvider (Consumer + read), ProjectProvider (read) | PhotoThumbnail, _PhotoViewerScreen, PhotoSourceDialog, PhotoNameDialog |
| 25 | `FormsListScreen` | `/forms` | `lib/features/forms/presentation/screens/forms_list_screen.dart` | InspectorFormProvider (watch + read), ProjectProvider (watch + read), AuthProvider (watch) | FormAccordion, StatusPillBar |
| 26 | `FormViewerScreen` | (via forms) | `lib/features/forms/presentation/screens/form_viewer_screen.dart` | InspectorFormProvider (read), ProjectProvider (read), AuthProvider (read), FormPdfService (read) | _PdfPreviewScreen |
| 27 | `MdotHubScreen` | `/form/:responseId` | `lib/features/forms/presentation/screens/mdot_hub_screen.dart` | InspectorFormProvider (read), ProjectProvider (read), AuthProvider (read), FormPdfService (read) | HubHeaderContent, HubProctorContent, HubQuickTestContent, SummaryTiles, _PdfPreviewScreen, FormFillScreen, QuickTestEntryScreen |
| 28 | `TodosScreen` | `/todos` | `lib/features/todos/presentation/screens/todos_screen.dart` | TodoProvider (Consumer x4 + read), ProjectProvider (read), AuthProvider (watch) | -- |
| 29 | `ToolboxHomeScreen` | `/toolbox` | `lib/features/toolbox/presentation/screens/toolbox_home_screen.dart` | (none) | -- |
| 30 | `PdfImportPreviewScreen` | `/import/preview/:projectId` | `lib/features/pdf/presentation/screens/pdf_import_preview_screen.dart` | (via extra param) | BidItemDialog |
| 31 | `MpImportPreviewScreen` | `/mp-import/preview/:projectId` | `lib/features/pdf/presentation/screens/mp_import_preview_screen.dart` | (via extra param) | -- |
| 32 | `TrashScreen` | `/settings/trash` | `lib/features/settings/presentation/screens/trash_screen.dart` | DatabaseService (read) | ConfirmationDialog |
| 33 | `EditProfileScreen` | `/edit-profile` | `lib/features/settings/presentation/screens/edit_profile_screen.dart` | AuthProvider (Consumer + read) | -- |
| 34 | `AdminDashboardScreen` | `/admin-dashboard` | `lib/features/settings/presentation/screens/admin_dashboard_screen.dart` | AdminProvider (Consumer + read), AuthProvider (read) | MemberDetailSheet |
| 35 | `PersonnelTypesScreen` | `/personnel-types/:projectId` | `lib/features/settings/presentation/screens/personnel_types_screen.dart` | PersonnelTypeProvider (Consumer + read) | -- |
| 36 | `SyncDashboardScreen` | `/sync/dashboard` | `lib/features/sync/presentation/screens/sync_dashboard_screen.dart` | SyncProvider (watch + read), DatabaseService (read) | -- |
| 37 | `ConflictViewerScreen` | `/sync/conflicts` | `lib/features/sync/presentation/screens/conflict_viewer_screen.dart` | DatabaseService (read), SyncRegistry (read) | -- |
| 38 | `ProjectSelectionScreen` | `/sync/project-selection` | `lib/features/sync/presentation/screens/project_selection_screen.dart` | AuthProvider (read), DatabaseService (read) | -- |

**Total: 38 distinct screen classes** (excluding private state classes and internal sub-screens like _PhotoViewerScreen, _PdfPreviewScreen, etc.)

---

## 2. Widget Dependency Graph

### Shared Widgets (`lib/shared/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `ConfirmationDialog` | `confirmation_dialog.dart` | ProjectListScreen, TrashScreen, and inline `showDialog` calls in multiple screens |
| `EmptyStateWidget` | `empty_state_widget.dart` | Various list screens (projects, entries, forms, gallery) |
| `ContextualFeedbackOverlay` | `contextual_feedback_overlay.dart` | (utility overlay) |
| `PermissionDialog` / `_StoragePermissionDialog` | `permission_dialog.dart` | Photo/camera permission flows |
| `SearchBarField` | `search_bar_field.dart` | ProjectListScreen, QuantitiesScreen, GalleryScreen |
| `StaleConfigWarning` | `stale_config_warning.dart` | ScaffoldWithNavBar (shell) |
| `VersionBanner` | `version_banner.dart` | ScaffoldWithNavBar (shell) |
| `ViewOnlyBanner` | `view_only_banner.dart` | HomeScreen, EntriesListScreen (viewer role) |

### Entries Feature Widgets (`lib/features/entries/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `EntryBasicsSection` | `entry_basics_section.dart` | EntryEditorScreen |
| `EntryActivitiesSection` | `entry_activities_section.dart` | EntryEditorScreen |
| `EntryContractorsSection` | `entry_contractors_section.dart` | EntryEditorScreen |
| `EntryPhotosSection` | `entry_photos_section.dart` | EntryEditorScreen |
| `EntryFormsSection` | `entry_forms_section.dart` | EntryEditorScreen |
| `EntryQuantitiesSection` | `entry_quantities_section.dart` | EntryEditorScreen |
| `EntrySafetySection` | `entry_safety_section.dart` | EntryEditorScreen |
| `EntryActionBar` / `EntryStatusSection` | `entry_action_bar.dart` | EntryEditorScreen, EntryReviewScreen |
| `ContractorEditorWidget` / `ContractorSummaryWidget` | `contractor_editor_widget.dart` | EntryEditorScreen, EntryContractorsSection, EntryReviewScreen |
| `DraftEntryTile` | `draft_entry_tile.dart` | DraftsListScreen |
| `EntryFormCard` | `entry_form_card.dart` | EntryFormsSection |
| `StatusBadge` | `status_badge.dart` | EntriesListScreen, HomeScreen |
| `ReviewFieldRow` | `review_field_row.dart` | EntryReviewScreen |
| `ReviewMissingWarning` | `review_missing_warning.dart` | EntryReviewScreen |
| `SimpleInfoRow` | `simple_info_row.dart` | EntryReviewScreen |
| `FormSelectionDialog` | `form_selection_dialog.dart` | EntryFormsSection |
| `QuantityDialogResult` (data class) | `quantity_dialog.dart` | EntryQuantitiesSection |
| `PhotoDetailResult` (data class) | `photo_detail_dialog.dart` | EntryPhotosSection |
| `BidItemPickerSheet` (function) | `bid_item_picker_sheet.dart` | EntryQuantitiesSection |
| `SubmittedBanner` | `submitted_banner.dart` | EntryEditorScreen |

### Entries Report Widgets (`lib/features/entries/presentation/screens/report_widgets/`)

| Widget / Function | File | Used By |
|-------------------|------|---------|
| `reportAddContractorSheet` | `report_add_contractor_sheet.dart` | EntryContractorsSection |
| `reportAddPersonnelTypeDialog` | `report_add_personnel_type_dialog.dart` | EntryContractorsSection |
| `reportAddQuantityDialog` | `report_add_quantity_dialog.dart` | EntryQuantitiesSection |
| `reportDebugPdfActionsDialog` | `report_debug_pdf_actions_dialog.dart` | EntryEditorScreen |
| `reportDeletePersonnelTypeDialog` | `report_delete_personnel_type_dialog.dart` | EntryContractorsSection |
| `reportLocationEditDialog` | `report_location_edit_dialog.dart` | EntryEditorScreen |
| `reportPdfActionsDialog` | `report_pdf_actions_dialog.dart` | EntryEditorScreen |
| `reportPhotoDetailDialog` | `report_photo_detail_dialog.dart` | EntryPhotosSection |
| `reportWeatherEditDialog` | `report_weather_edit_dialog.dart` | EntryEditorScreen |

### Dashboard Widgets (`lib/features/dashboard/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `DashboardStatCard` | `dashboard_stat_card.dart` | ProjectDashboardScreen |
| `BudgetOverviewCard` / `_BudgetStatBox` | `budget_overview_card.dart` | ProjectDashboardScreen |
| `AlertItemRow` | `alert_item_row.dart` | ProjectDashboardScreen |
| `TrackedItemRow` | `tracked_item_row.dart` | ProjectDashboardScreen |

### Projects Widgets (`lib/features/projects/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `AddContractorDialog` | `add_contractor_dialog.dart` | ProjectSetupScreen |
| `AddEquipmentDialog` | `add_equipment_dialog.dart` | ProjectSetupScreen |
| `AddLocationDialog` | `add_location_dialog.dart` | ProjectSetupScreen |
| `BidItemDialog` | `bid_item_dialog.dart` | ProjectSetupScreen, PdfImportPreviewScreen, QuantitiesScreen |
| `PayItemSourceDialog` / `_SourceOption` | `pay_item_source_dialog.dart` | ProjectSetupScreen |
| `ProjectSwitcher` / `_ProjectSwitcherSheet` | `project_switcher.dart` | ScaffoldWithNavBar (shell) AppBar |
| `ProjectDetailsForm` | `project_details_form.dart` | ProjectSetupScreen |
| `EquipmentChip` | `equipment_chip.dart` | ProjectSetupScreen |

### Quantities Widgets (`lib/features/quantities/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `BidItemCard` | `bid_item_card.dart` | QuantitiesScreen |
| `BidItemDetailSheet` | `bid_item_detail_sheet.dart` | QuantitiesScreen |
| `QuantitySummaryHeader` | `quantity_summary_header.dart` | QuantitiesScreen |

### Settings Widgets (`lib/features/settings/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `ClearCacheDialog` | `clear_cache_dialog.dart` | SettingsScreen |
| `MemberDetailSheet` | `member_detail_sheet.dart` | AdminDashboardScreen |
| `SectionHeader` | `section_header.dart` | SettingsScreen, AdminDashboardScreen |
| `SignOutDialog` | `sign_out_dialog.dart` | SettingsScreen |
| `SyncSection` | `sync_section.dart` | SettingsScreen |
| `ThemeSection` | `theme_section.dart` | SettingsScreen |

### Sync Widgets (`lib/features/sync/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `SyncStatusIcon` | `sync_status_icon.dart` | HomeScreen AppBar |
| `DeletionNotificationBanner` | `deletion_notification_banner.dart` | HomeScreen |

### Photos Widgets (`lib/features/photos/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `PhotoThumbnail` | `photo_thumbnail.dart` | GalleryScreen, EntryPhotosSection |
| `PhotoNameDialog` | `photo_name_dialog.dart` | GalleryScreen, EntryPhotosSection |
| `PhotoSourceDialog` | `photo_source_dialog.dart` | GalleryScreen, EntryPhotosSection |

### Forms Widgets (`lib/features/forms/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `FormAccordion` / `_LetterBadge` / `_StatusBadge` | `form_accordion.dart` | FormsListScreen |
| `FormThumbnail` | `form_thumbnail.dart` | EntryFormsSection, FormsListScreen |
| `HubHeaderContent` | `hub_header_content.dart` | MdotHubScreen |
| `HubProctorContent` | `hub_proctor_content.dart` | MdotHubScreen |
| `HubQuickTestContent` | `hub_quick_test_content.dart` | MdotHubScreen |
| `StatusPillBar` / `_StatusPill` | `status_pill_bar.dart` | FormsListScreen |
| `SummaryTiles` | `summary_tiles.dart` | MdotHubScreen |

### PDF Widgets (`lib/features/pdf/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `PdfImportProgressDialog` | `pdf_import_progress_dialog.dart` | PdfImportHelper flow |

### Auth Widgets (`lib/features/auth/presentation/widgets/`)

| Widget | File | Used By |
|--------|------|---------|
| `UserAttributionText` | `user_attribution_text.dart` | EntriesListScreen |

---

## 3. Provider Dependency Graph

### Presentation-Layer Providers

| Provider | File | Screens That Consume It |
|----------|------|------------------------|
| `AuthProvider` | `lib/features/auth/presentation/providers/auth_provider.dart` | LoginScreen, RegisterScreen, ForgotPasswordScreen, OtpVerificationScreen, UpdatePasswordScreen, ProfileSetupScreen, CompanySetupScreen, PendingApprovalScreen, AccountStatusScreen, SettingsScreen, EditProfileScreen, AdminDashboardScreen, HomeScreen, ProjectListScreen, EntriesListScreen, EntryEditorScreen, ProjectSetupScreen, QuantitiesScreen, FormsListScreen, FormViewerScreen, MdotHubScreen, TodosScreen, ProjectSelectionScreen |
| `ProjectProvider` | `lib/features/projects/presentation/providers/project_provider.dart` | ProjectDashboardScreen, HomeScreen, ProjectListScreen, ProjectSetupScreen, EntriesListScreen, EntryEditorScreen, QuantitiesScreen, QuantityCalculatorScreen, FormsListScreen, FormViewerScreen, MdotHubScreen, GalleryScreen, ProjectSwitcher |
| `DailyEntryProvider` | `lib/features/entries/presentation/providers/daily_entry_provider.dart` | ProjectDashboardScreen, HomeScreen, EntriesListScreen, EntryEditorScreen, DraftsListScreen |
| `LocationProvider` | `lib/features/locations/presentation/providers/location_provider.dart` | ProjectDashboardScreen, ProjectSetupScreen, EntryEditorScreen, EntriesListScreen, DraftsListScreen, EntryReviewScreen, ReviewSummaryScreen |
| `ContractorProvider` | `lib/features/contractors/presentation/providers/contractor_provider.dart` | ProjectDashboardScreen, ProjectSetupScreen, EntryEditorScreen, HomeScreen |
| `EquipmentProvider` | `lib/features/contractors/presentation/providers/equipment_provider.dart` | ProjectSetupScreen, EntryEditorScreen, HomeScreen |
| `BidItemProvider` | `lib/features/quantities/presentation/providers/bid_item_provider.dart` | ProjectDashboardScreen, ProjectSetupScreen, QuantitiesScreen, EntryEditorScreen, HomeScreen |
| `EntryQuantityProvider` | `lib/features/quantities/presentation/providers/entry_quantity_provider.dart` | ProjectDashboardScreen, QuantitiesScreen, EntryEditorScreen |
| `PersonnelTypeProvider` | `lib/features/contractors/presentation/providers/personnel_type_provider.dart` | PersonnelTypesScreen, EntryEditorScreen, HomeScreen |
| `PhotoProvider` | `lib/features/photos/presentation/providers/photo_provider.dart` | EntryEditorScreen, HomeScreen |
| `GalleryProvider` | `lib/features/gallery/presentation/providers/gallery_provider.dart` | GalleryScreen |
| `InspectorFormProvider` | `lib/features/forms/presentation/providers/inspector_form_provider.dart` | FormsListScreen, FormViewerScreen, MdotHubScreen, EntryEditorScreen |
| `TodoProvider` | `lib/features/todos/presentation/providers/todo_provider.dart` | TodosScreen |
| `CalendarFormatProvider` | `lib/features/entries/presentation/providers/calendar_format_provider.dart` | HomeScreen |
| `SyncProvider` | `lib/features/sync/presentation/providers/sync_provider.dart` | ScaffoldWithNavBar (shell), SyncDashboardScreen, SyncStatusIcon, SyncSection |
| `AdminProvider` | `lib/features/settings/presentation/providers/admin_provider.dart` | AdminDashboardScreen, MemberDetailSheet |
| `ThemeProvider` | `lib/features/settings/presentation/providers/theme_provider.dart` | ThemeSection (SettingsScreen) |
| `ProjectSettingsProvider` | `lib/features/projects/presentation/providers/project_settings_provider.dart` | SettingsScreen |
| `AppConfigProvider` | `lib/features/auth/presentation/providers/app_config_provider.dart` | SettingsScreen, UpdateRequiredScreen, ScaffoldWithNavBar (shell) |
| `CalculatorProvider` | `lib/features/calculator/presentation/providers/calculator_provider.dart` | CalculatorScreen, QuantityCalculatorScreen |

### Non-Provider Services Accessed via `context.read<>`

| Service | Screens |
|---------|---------|
| `DatabaseService` | EntryEditorScreen, ProjectListScreen, SettingsScreen, TrashScreen, SyncDashboardScreen, ConflictViewerScreen, ProjectSelectionScreen, DeletionNotificationBanner |
| `AuthService` | CompanySetupScreen, PendingApprovalScreen |
| `FormPdfService` | FormViewerScreen, MdotHubScreen |
| `SyncRegistry` | ConflictViewerScreen |

### Provider Access Patterns

| Pattern | Count | Files |
|---------|-------|-------|
| `context.read<>` | 100+ | All screens |
| `Consumer<>` | 32 | 16 files |
| `context.watch<>` | 10 | 8 files |
| `Provider.of<>` | 0 | (not used) |

---

## 4. Theme Token Usage Matrix

### Theme System Architecture

```
AppTheme (facade, lib/core/theme/app_theme.dart, ~1540 lines)
  |-- re-exports AppColors (lib/core/theme/colors.dart, ~170 lines)
  |-- re-exports DesignConstants (lib/core/theme/design_constants.dart, ~60 lines)
  |-- ThemeData builders: darkTheme, lightTheme, highContrastTheme
  |-- Utility methods: getPrimaryGradient, getAccentGradient, getGlassmorphicDecoration
  |-- Domain helpers: getWeatherColor, getEntryStatusColor
```

### Color Tokens (AppTheme / AppColors)

| Token Group | Tokens | Count in AppTheme |
|-------------|--------|-------------------|
| Primary | primaryCyan, primaryBlue, primaryDark, primaryLight | 4 |
| Accent | accentAmber, accentOrange, accentGold | 3 |
| Semantic / Status | statusSuccess, statusWarning, statusError, statusInfo | 4 |
| Legacy aliases | secondaryAmber, success, warning, error | 4 |
| Dark surfaces | backgroundDark, surfaceDark, surfaceElevated, surfaceHighlight, surfaceBright, surfaceGlass | 6 |
| Dark text | textPrimary, textSecondary, textTertiary, textInverse | 4 |
| Light surfaces | lightBackground, lightSurface, lightSurfaceElevated, lightSurfaceHighlight | 4 |
| Light text | lightTextPrimary, lightTextSecondary, lightTextTertiary | 3 |
| High Contrast | hcBackground, hcSurface, hcSurfaceElevated, hcBorder, hcPrimary, hcAccent, hcError, hcWarning, hcTextPrimary, hcTextSecondary | 10 |
| Weather | weatherSunny, weatherCloudy, weatherOvercast, weatherRainy, weatherSnow, weatherWindy | 6 |
| Overlay | overlayLight | 1 |
| Gradients | gradientPrimary, gradientAccent | 2 |

### Spacing Tokens (AppTheme / DesignConstants)

| Token | Value | Usage Pattern |
|-------|-------|---------------|
| `space1` | 4.0 | Tight spacing |
| `space2` | 8.0 | Default tight |
| `space3` | 12.0 | Small padding |
| `space4` | 16.0 | Standard padding |
| `space5` | 20.0 | Section gaps |
| `space6` | 24.0 | Large gaps |
| `space8` | 32.0 | Section separators |
| `space10` | 40.0 | Large separators |

### Radius Tokens

| Token | Value |
|-------|-------|
| `radiusSmall` | 8.0 |
| `radiusMedium` | 12.0 |
| `radiusLarge` | 16.0 |
| `radiusXLarge` | 24.0 |
| `radiusFull` | 999.0 |

### Touch Target Tokens

| Token | Value |
|-------|-------|
| `touchTargetMin` | 48.0 |
| `touchTargetComfortable` | (defined in DesignConstants) |
| `touchTargetLarge` | (defined in DesignConstants) |

### ThemeData Builders

| Builder | Lines | Notes |
|---------|-------|-------|
| `darkTheme` | 130-764 | Full Material 3 theme with all component themes |
| `lightTheme` | 765-1124 | Mirror of dark with light palette |
| `highContrastTheme` | 1125-1492 | WCAG AAA accessible theme |

---

## 5. Hardcoded Value Hotspots

### Screens with MOST hardcoded numeric values (bypassing tokens)

Based on `SizedBox(height: N)`, `EdgeInsets.all(N)`, `BorderRadius.circular(N)`, `TextStyle(fontSize: N)`, `FontWeight.` searches:

| File | Hardcoded Spacing | Hardcoded Radius | Hardcoded FontSize | Hardcoded FontWeight | Hardcoded Colors (`Colors.`) | Severity |
|------|------------------|-----------------|--------------------|--------------------|----------------------------|----------|
| **sync/conflict_viewer_screen.dart** | 5 (4,8,12,16) | 1 (4) | 1 (12) | 2 | 4 (green, orange, grey) | HIGH |
| **sync/project_selection_screen.dart** | 4 (8,12,16,32) | 0 | 0 | 0 | 2 (red, grey) | HIGH |
| **sync/sync_dashboard_screen.dart** | 5 (8,16) | 0 | 3 (11,12,20) | 3 | 7 (red,amber,green,grey,white,orange) | HIGH |
| **settings/admin_dashboard_screen.dart** | 3 (16,32) | 3 (4,12) | 0 | 5 | 5 (grey,white) | HIGH |
| **settings/personnel_types_screen.dart** | 3 (8,16) | 0 | 0 | 1 | 0 | MEDIUM |
| **settings/trash_screen.dart** | 0 | 0 | 4 (12,14,18) | 2 | 0 | MEDIUM |
| **settings/settings_screen.dart** | 0 | 1 (12) | 1 (11) | 1 | 1 (white) | MEDIUM |
| **settings/member_detail_sheet.dart** | 0 | 2 (2,12) | 2 (13) | 5 | 3 (grey) | MEDIUM |
| **projects/project_list_screen.dart** | 4 (12,16,32) | 5 (6,8,10,12) | 1 (13) | 0 | 0 | HIGH |
| **projects/project_setup_screen.dart** | 4 (16) | 1 (4) | 0 | 0 | 0 | MEDIUM |
| **projects/pay_item_source_dialog.dart** | 2 (8,12) | 3 (6,8) | 1 (14) | 0 | 0 | MEDIUM |
| **projects/project_switcher.dart** | 0 | 2 (2,8) | 0 | 0 | 2 (grey) | LOW |
| **gallery/gallery_screen.dart** | 0 | 0 | 2 (12) | 0 | 6 (black,white,white54,black87,white70) | HIGH |
| **photos/photo_thumbnail.dart** | 1 (2) | 3 (4,8) | 0 | 0 | 0 | LOW |
| **photos/photo_name_dialog.dart** | 0 | 1 (8) | 1 (12) | 0 | 0 | LOW |
| **pdf/pdf_import_preview_screen.dart** | 0 | 1 (4) | 6 (11,12,13,14) | 1 | 0 | MEDIUM |
| **pdf/mp_import_preview_screen.dart** | 0 | 0 | 3 (10,12) | 0 | 0 | MEDIUM |
| **forms/hub_proctor_content.dart** | 0 | 0 | 4 (11,12) | 3 | 0 | MEDIUM |
| **forms/hub_header_content.dart** | 0 | 0 | 1 (10) | 1 | 0 | LOW |
| **forms/hub_quick_test_content.dart** | 0 | 0 | 1 (11) | 0 | 0 | LOW |
| **entries/home_screen.dart** | 0 | 0 | 3 (14) | 0 | 0 | LOW |
| **entries/entry_editor_screen.dart** | 0 | 0 | 4 (14) | 0 | 0 | LOW |
| **sync/deletion_notification_banner.dart** | 0 | 0 | 0 | 2 | 0 | LOW |
| **sync/sync_status_icon.dart** | 0 | 0 | 0 | 0 | 3 (red, amber, green) | MEDIUM |

### Summary of Hardcoded Values

| Pattern | Est. Count | Note |
|---------|-----------|------|
| `Colors.` in presentation | 40+ (truncated) | Flutter Material colors bypassing AppTheme |
| `BorderRadius.circular(N)` with literal | 20+ | Should use `AppTheme.radius*` |
| `EdgeInsets.all(N)` with literal | 15+ | Should use `AppTheme.space*` |
| `SizedBox(height: N)` with literal | 20+ | Should use `AppTheme.space*` |
| `TextStyle(fontSize: N)` inline | 40+ (truncated) | Should use theme textTheme |
| `FontWeight.` inline | 40+ (truncated) | Should be in textTheme |
| `Color(0x...)` in presentation | 0 | Good -- no raw hex colors in presentation |
| `AppColors.` direct in presentation | 0 | Good -- always goes through AppTheme |
| `DesignConstants.` direct in presentation | 0 | Good -- always goes through AppTheme |

### Adoption Split

- **Fully tokenized screens**: TodosScreen, ToolboxHomeScreen, EditProfileScreen, QuantityCalculatorScreen, most quantities widgets
- **Partially tokenized**: HomeScreen, EntriesListScreen, QuantitiesScreen (mix of tokens and literals)
- **Mostly hardcoded**: All sync screens, AdminDashboardScreen, ProjectListScreen, GalleryScreen (_PhotoViewerScreen)

---

## 6. Cross-Feature Dependencies

### Feature Import Graph (Presentation Layer)

| Source Feature | Imports From Feature | Files | What Is Imported |
|---------------|---------------------|-------|------------------|
| **entries** | projects | 3 screens | ProjectProvider |
| **entries** | locations | 5 screens | LocationProvider |
| **entries** | contractors | 3 screens | ContractorProvider, EquipmentProvider, PersonnelTypeProvider |
| **entries** | quantities | 1 screen | EntryQuantityProvider, BidItemProvider |
| **entries** | photos | 1 screen | PhotoProvider |
| **entries** | forms | 1 screen | InspectorFormProvider |
| **entries** | auth | 2 screens | AuthProvider, UserAttributionText |
| **entries** | pdf | 1 screen | PdfService |
| **dashboard** | projects | 1 screen | ProjectProvider |
| **dashboard** | entries | 1 screen | DailyEntryProvider |
| **dashboard** | locations | 1 screen | LocationProvider |
| **dashboard** | quantities | 1 screen | BidItemProvider, EntryQuantityProvider, BudgetSanityChecker, BidItem model |
| **dashboard** | contractors | 1 screen | ContractorProvider |
| **projects** | auth | 1 screen | AuthProvider |
| **projects** | locations | 1 screen | LocationProvider (Consumer) |
| **projects** | contractors | 1 screen | ContractorProvider, EquipmentProvider |
| **projects** | quantities | 1 screen | BidItemProvider |
| **quantities** | projects | 1 screen | ProjectProvider |
| **quantities** | auth | 1 screen | AuthProvider |
| **quantities** | calculator | 1 screen | CalculatorProvider |
| **gallery** | projects | 1 screen | ProjectProvider |
| **forms** | projects | 2 screens | ProjectProvider |
| **forms** | auth | 2 screens | AuthProvider |
| **settings** | auth | 3 screens | AuthProvider, AuthService |
| **settings** | sync | 1 widget | SyncProvider |
| **settings** | projects | 1 widget | ProjectSettingsProvider |
| **sync** | auth | 1 screen | AuthProvider |
| **todos** | projects | 1 screen | ProjectProvider |
| **todos** | auth | 1 screen | AuthProvider |

### Most-Depended-Upon Features (by import count)

1. **auth** (AuthProvider) -- 23 screens
2. **projects** (ProjectProvider) -- 13 screens
3. **entries** (DailyEntryProvider) -- 5 screens
4. **locations** (LocationProvider) -- 7 screens
5. **quantities** (BidItemProvider + EntryQuantityProvider) -- 6 screens
6. **contractors** (ContractorProvider + EquipmentProvider) -- 5 screens

---

## 7. Bottom Sheet / Dialog Registry

### Modal Bottom Sheets (`showModalBottomSheet`)

| Location | File | What It Shows |
|----------|------|---------------|
| AdminDashboardScreen:367 | `admin_dashboard_screen.dart` | MemberDetailSheet |
| BidItemDetailSheet.show:17 | `bid_item_detail_sheet.dart` | BidItemDetailSheet (DraggableScrollableSheet) |
| ProjectSwitcher:69 | `project_switcher.dart` | _ProjectSwitcherSheet |
| PhotoSourceDialog.show:25 | `photo_source_dialog.dart` | PhotoSourceDialog |
| GalleryScreen:304 | `gallery_screen.dart` | Photo options sheet |
| HomeScreen:1604 | `home_screen.dart` | Entry options |
| BidItemPickerSheet:16 | `bid_item_picker_sheet.dart` | BidItem picker (DraggableScrollableSheet) |
| ReportAddContractorSheet:16 | `report_add_contractor_sheet.dart` | Add contractor to entry |

### Dialogs (`showDialog`)

| Location | File | What It Shows |
|----------|------|---------------|
| ConfirmationDialog (shared) | `confirmation_dialog.dart` | 3 dialog variants (confirm, destructive, tri-choice) |
| PermissionDialog (shared) | `permission_dialog.dart` | _StoragePermissionDialog |
| TodosScreen:345,361,381,407 | `todos_screen.dart` | Create/edit/delete todo dialogs |
| AdminDashboardScreen:304,334 | `admin_dashboard_screen.dart` | Approve/reject confirmation |
| PersonnelTypesScreen:152,249,334 | `personnel_types_screen.dart` | Add/edit/delete personnel type |
| SettingsScreen:41,83 | `settings_screen.dart` | App version, theme selection |
| TrashScreen:283,324 | `trash_screen.dart` | Restore/purge confirmation |
| ClearCacheDialog:11 | `clear_cache_dialog.dart` | Clear cache confirmation |
| MemberDetailSheet:317 | `member_detail_sheet.dart` | Role change confirmation |
| SignOutDialog:12 | `sign_out_dialog.dart` | Sign out confirmation |
| ProjectListScreen:474,566 | `project_list_screen.dart` | Delete/archive project |
| AddContractorDialog:17 | `add_contractor_dialog.dart` | Add contractor form |
| AddEquipmentDialog:17 | `add_equipment_dialog.dart` | Add equipment form |
| AddLocationDialog:17 | `add_location_dialog.dart` | Add location form |
| BidItemDialog:23 | `bid_item_dialog.dart` | Add/edit bid item form |
| PayItemSourceDialog:18 | `pay_item_source_dialog.dart` | Choose pay item source |
| PhotoNameDialog:66 | `photo_name_dialog.dart` | Name photo with metadata |
| PdfService:322 | `pdf_service.dart` | PDF password prompt |
| PdfImportHelper:119 | `pdf_import_helper.dart` | Import error |
| PdfImportPreviewScreen:254 | `pdf_import_preview_screen.dart` | Edit bid item |
| PdfImportProgressManager:37 | `pdf_import_progress_manager.dart` | PdfImportProgressDialog |
| FormViewerScreen:223 | `form_viewer_screen.dart` | Discard changes confirmation |

### DraggableScrollableSheet (inside bottom sheets)

| Location | File |
|----------|------|
| BidItemDetailSheet:37 | `bid_item_detail_sheet.dart` |
| BidItemPickerSheet:29 | `bid_item_picker_sheet.dart` |

### Total Modal Surfaces: ~40 (8 bottom sheets + ~30 dialogs + 2 DraggableScrollable)

---

## 8. Route Map

### Auth Routes (Full-screen, no nav)

| Path | Name | Screen Class | Type |
|------|------|-------------|------|
| `/login` | login | LoginScreen | Full |
| `/register` | register | RegisterScreen | Full |
| `/forgot-password` | forgotPassword | ForgotPasswordScreen | Full |
| `/verify-otp` | verifyOtp | OtpVerificationScreen | Full |
| `/update-password` | updatePassword | UpdatePasswordScreen | Full |
| `/update-required` | updateRequired | UpdateRequiredScreen | Full |

### Onboarding Routes (Full-screen, no nav)

| Path | Name | Screen Class | Type |
|------|------|-------------|------|
| `/profile-setup` | profileSetup | ProfileSetupScreen | Full |
| `/company-setup` | companySetup | CompanySetupScreen | Full |
| `/pending-approval` | pendingApproval | PendingApprovalScreen | Full |
| `/account-status` | accountStatus | AccountStatusScreen | Full |

### Shell Routes (Bottom nav bar via ScaffoldWithNavBar)

| Path | Name | Screen Class | Nav Tab |
|------|------|-------------|---------|
| `/` | dashboard | ProjectDashboardScreen | Dashboard |
| `/calendar` | home | HomeScreen | Calendar |
| `/projects` | projects | ProjectListScreen | Projects |
| `/settings` | settings | SettingsScreen | Settings |

### Feature Routes (Full-screen, outside shell)

| Path | Name | Screen Class | Type |
|------|------|-------------|------|
| `/settings/trash` | trash | TrashScreen | Full |
| `/edit-profile` | editProfile | EditProfileScreen | Full |
| `/admin-dashboard` | admin-dashboard | AdminDashboardScreen | Full (admin guard) |
| `/entry/:projectId/:date` | entry | EntryEditorScreen | Full |
| `/report/:entryId` | report | EntryEditorScreen | Full |
| `/project/new` | project-new | ProjectSetupScreen | Full |
| `/project/:projectId/edit` | project-edit | ProjectSetupScreen | Full |
| `/quantities` | quantities | QuantitiesScreen | Full |
| `/quantity-calculator/:entryId` | quantity-calculator | QuantityCalculatorScreen | Full |
| `/entries` | entries | EntriesListScreen | Full |
| `/drafts/:projectId` | drafts | DraftsListScreen | Full |
| `/review` | review | EntryReviewScreen | Full (requires extra) |
| `/review-summary` | review-summary | ReviewSummaryScreen | Full (requires extra) |
| `/personnel-types/:projectId` | personnel-types | PersonnelTypesScreen | Full |
| `/import/preview/:projectId` | import-preview | PdfImportPreviewScreen | Full (requires extra) |
| `/mp-import/preview/:projectId` | mp-import-preview | MpImportPreviewScreen | Full (requires extra) |
| `/toolbox` | toolbox | ToolboxHomeScreen | Full |
| `/forms` | forms | FormsListScreen | Full |
| `/form/:responseId` | form-fill | MdotHubScreen | Full |
| `/calculator` | calculator | CalculatorScreen | Full |
| `/gallery` | gallery | GalleryScreen | Full |
| `/todos` | todos | TodosScreen | Full |
| `/sync/dashboard` | sync-dashboard | SyncDashboardScreen | Full |
| `/sync/conflicts` | sync-conflicts | ConflictViewerScreen | Full |
| `/sync/project-selection` | sync-project-selection | ProjectSelectionScreen | Full |

### Navigation Shell Structure

```
ScaffoldWithNavBar
  |-- AppBar: ProjectSwitcher (on '/' and '/calendar' only)
  |-- Body:
  |   |-- VersionBanner (if update available)
  |   |-- StaleConfigWarning (if config stale)
  |   |-- MaterialBanner (if sync stale)
  |   |-- [screen content]
  |-- BottomNavigationBar: 4 tabs
  |     Dashboard | Calendar | Projects | Settings
```

**Total Routes: 35** (6 auth + 4 onboarding + 4 shell + 25 full-screen - 4 duplicates with shared screens)

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Screen classes | 38 |
| Widget classes (presentation) | 80+ |
| Shared widgets | 8 |
| Providers | 20 |
| Routes | 35 |
| Bottom sheets | 8 |
| Dialogs | ~30 |
| DraggableScrollableSheets | 2 |
| Theme tokens (color) | 51 |
| Theme tokens (spacing) | 8 |
| Theme tokens (radius) | 5 |
| Theme tokens (elevation) | 4 |
| Theme tokens (touch target) | 3 |
| Theme tokens (animation) | 5 |
| Hardcoded `Colors.` in presentation | 40+ |
| Hardcoded `BorderRadius.circular(N)` | 20+ |
| Hardcoded `TextStyle(fontSize: N)` | 40+ |
| Hardcoded `FontWeight.` inline | 40+ |
| Cross-feature import relationships | 28 |

### Key Refactoring Observations

1. **Dual token system**: `AppColors` and `DesignConstants` exist as source-of-truth, while `AppTheme` re-exports everything. Presentation code correctly uses `AppTheme.*` (never `AppColors.*` or `DesignConstants.*` directly). This facade pattern is clean but the re-export layer adds ~120 lines of boilerplate.

2. **Inconsistent adoption**: Newer screens (TodosScreen, ToolboxHomeScreen, quantities widgets) fully use `AppTheme.space*` and `AppTheme.radius*` tokens. Older screens (sync screens, admin dashboard, project list) use raw numeric literals extensively.

3. **Typography is not tokenized**: No `AppTheme.text*` style tokens exist. All screens use inline `TextStyle(fontSize: N, fontWeight: ...)` or occasionally `Theme.of(context).textTheme.*`. This is the largest gap.

4. **`Colors.*` usage is the biggest color problem**: Zero `Color(0x...)` in presentation (good), zero `AppColors.*` direct access (good), but 40+ uses of Flutter's `Colors.red`, `Colors.grey`, `Colors.white`, etc. that bypass the theme system entirely.

5. **EntryEditorScreen is the dependency hub**: It reads from 11 different providers and uses 10+ widget classes. Any refactor must handle this screen's complexity carefully.

6. **Three ThemeData builders (dark/light/high-contrast)**: Each is 400-600+ lines with fully specified component themes. Any design token changes need to be applied across all three.
