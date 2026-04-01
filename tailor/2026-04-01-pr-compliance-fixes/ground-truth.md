# Ground Truth

All literals verified against codebase on 2026-04-01.

## Route Paths (from app_router.dart:125-536)

| Route | Name | Screen | Category |
|-------|------|--------|----------|
| `/login` | login | LoginScreen | Auth |
| `/register` | register | RegisterScreen | Auth |
| `/forgot-password` | forgotPassword | ForgotPasswordScreen | Auth |
| `/verify-otp` | verifyOtp | OtpVerificationScreen | Auth |
| `/update-password` | updatePassword | UpdatePasswordScreen | Auth |
| `/update-required` | updateRequired | UpdateRequiredScreen | Auth |
| `/consent` | consent | ConsentScreen | Auth |
| `/profile-setup` | profileSetup | ProfileSetupScreen | Onboarding |
| `/company-setup` | companySetup | CompanySetupScreen | Onboarding |
| `/pending-approval` | pendingApproval | PendingApprovalScreen | Onboarding |
| `/account-status` | accountStatus | AccountStatusScreen | Onboarding |
| `/` | dashboard | ProjectDashboardScreen | Shell (nav) |
| `/calendar` | home | HomeScreen | Shell (nav) |
| `/projects` | projects | ProjectListScreen | Shell (nav) |
| `/settings` | settings | SettingsScreen | Shell (nav) |
| `/settings/trash` | trash | TrashScreen | Settings |
| `/edit-profile` | editProfile | EditProfileScreen | Settings |
| `/admin-dashboard` | admin-dashboard | AdminDashboardScreen | Settings |
| `/help-support` | help-support | HelpSupportScreen | Settings |
| `/legal-document` | legal-document | LegalDocumentScreen | Settings |
| `/oss-licenses` | oss-licenses | OssLicensesScreen | Settings |
| `/entry/:projectId/:date` | entry | EntryEditorScreen | Entry |
| `/report/:entryId` | report | EntryEditorScreen | Entry |
| `/entries` | entries | EntriesListScreen | Entry |
| `/drafts/:projectId` | drafts | DraftsListScreen | Entry |
| `/review` | review | EntryReviewScreen | Entry |
| `/review-summary` | review-summary | ReviewSummaryScreen | Entry |
| `/personnel-types/:projectId` | personnel-types | PersonnelTypesScreen | Entry |
| `/project/new` | project-new | ProjectSetupScreen | Project |
| `/project/:projectId/edit` | project-edit | ProjectSetupScreen | Project |
| `/quantities` | quantities | QuantitiesScreen | Project |
| `/quantity-calculator/:entryId` | quantity-calculator | QuantityCalculatorScreen | Project |
| `/import/preview/:projectId` | import-preview | PdfImportPreviewScreen | Form/PDF |
| `/mp-import/preview/:projectId` | mp-import-preview | MpImportPreviewScreen | Form/PDF |
| `/toolbox` | toolbox | ToolboxHomeScreen | Toolbox |
| `/forms` | forms | FormGalleryScreen | Toolbox |
| `/form/:responseId` | form-fill | FormViewerScreen (default) | Toolbox |
| `/calculator` | calculator | CalculatorScreen | Toolbox |
| `/gallery` | gallery | GalleryScreen | Toolbox |
| `/todos` | todos | TodosScreen | Toolbox |
| `/sync/dashboard` | sync-dashboard | SyncDashboardScreen | Sync |
| `/sync/conflicts` | sync-conflicts | ConflictViewerScreen | Sync |

**Total: 42 routes**

## Non-Restorable Routes (from app_router.dart:33-46)

```
'/profile-setup', '/company-setup', '/pending-approval',
'/account-status', '/consent', '/update-required'
```

## AUTOINCREMENT Locations (VERIFIED)

| File | Line | Table |
|------|------|-------|
| `sync_engine_tables.dart` | 22 | `change_log` |
| `sync_engine_tables.dart` | 38 | `conflict_log` |
| `sync_engine_tables.dart` | 89 | `storage_cleanup_queue` |
| `schema_verifier.dart` | 265 | `change_log` expected columns |
| `schema_verifier.dart` | 270 | `conflict_log` expected columns |
| `schema_verifier.dart` | 277 | `storage_cleanup_queue` expected columns |

## Stale test_harness References (VERIFIED)

| File | Lines | Count |
|------|-------|-------|
| `.claude/rules/testing/patrol-testing.md` | 7, 8, 160, 165, 170, 189, 199, 264, 370 | 9 |
| `no_stale_patrol_references.dart` | 11, 23, 29, 31 | 4 |
| `avoid_raw_database_delete.dart` | 28 | 1 |

## CI Workflow Values (VERIFIED)

| Key | Current | File:Line |
|-----|---------|-----------|
| `FLUTTER_VERSION` | `'3.32.2'` | `quality-gate.yml:19` |
| Supabase grep allowlist | `app_initializer.dart`, `background_sync_handler.dart` | `quality-gate.yml:199-200` |

## Feature Initializer Existence (VERIFIED)

| Feature | File | Status |
|---------|------|--------|
| Auth | `lib/features/auth/di/auth_initializer.dart` | EXISTS |
| Projects | `lib/features/projects/di/project_initializer.dart` | EXISTS |
| Entries | `lib/features/entries/di/entry_initializer.dart` | EXISTS |
| Forms | `lib/features/forms/di/form_initializer.dart` | EXISTS |
| Sync | `lib/features/sync/di/sync_providers.dart` | EXISTS (as SyncProviders) |
| Locations | — | MISSING (inline in app_initializer step 10) |
| Contractors | — | MISSING (inline) |
| Quantities | — | MISSING (inline) |
| Calculator | — | MISSING (inline) |
| Todos | — | MISSING (inline) |

## Dead Code (test_harness) — Confidence 1.0

| File | Importers | Status |
|------|-----------|--------|
| `lib/test_harness/flow_registry.dart` | 0 | DEAD |
| `lib/test_harness/harness_seed_data.dart` | 0 | DEAD |
| `lib/test_harness/screen_registry.dart` | 0 | DEAD |
| `lib/test_harness/stub_router.dart` | 0 | DEAD |
| `lib/test_harness/stub_services.dart` | 0 | DEAD |
