# Bug Triage Fix — Dependency Graph Analysis

## Direct Changes

### Permission Model (Auth Layer)
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/features/auth/data/models/user_role.dart` | `UserRole` enum | 5-58 | Remove `canWrite` getter (line 36), add `canManageProjects`, `canEditFieldData` |
| `lib/features/auth/data/models/user_profile.dart` | `UserProfile.canWrite` | 65 | Remove, add `canManageProjects`, `canEditFieldData` delegating to role |
| `lib/features/auth/presentation/providers/auth_provider.dart` | `AuthProvider.canWrite` | 183 | Remove |
| `lib/features/auth/presentation/providers/auth_provider.dart` | `AuthProvider.canEditProject` | 212 | Remove (dead code, BUG-012) |
| `lib/features/auth/presentation/providers/auth_provider.dart` | `AuthProvider.canCreateProject` | 194-196 | Keep (already correct: admin/engineer) |
| `lib/features/auth/presentation/providers/auth_provider.dart` | NEW | — | Add `canManageProjects` getter (admin/engineer) |
| `lib/features/auth/presentation/providers/auth_provider.dart` | NEW | — | Add `canEditFieldData` getter (all roles with loaded profile) |

### Project List Screen (UI Layer)
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_buildProjectCard` | 584-783 | Split `canWrite` param into `canManageProjects` + `canEditFieldData`. Edit button uses `canEditFieldData` (true for all), archive button uses `canManageProjects`. Fix tap targets (48dp). |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_buildMyProjectsTab` | 379-413 | Pass `canManageProjects` + `canEditFieldData` instead of `canWrite` |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_buildCompanyTab` | 415-472 | Same. Gate download for unassigned inspector. |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_buildArchivedTab` | 474-501 | Same param change |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_refresh` | 62-82 | Add `checkDnsReachability()` before sync |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_checkNetwork` | 88-91 | Make async, call `checkDnsReachability()` |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_handleRemoveFromDevice` | 171-209 | Clear `_selectedProject` + `settingsProvider.clearIfMatches` |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_showRemovalDialog` | 507-539 | Refresh DNS before gating syncAndRemove |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | `_showDownloadConfirmation` | 140-165 | Gate for unassigned inspector |

### Sync Engine
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/features/sync/engine/sync_engine.dart` | `SyncEngine._pull` | 1035-1100 | Add `_projectsAdapterCompleted` flag, reload `_syncedProjectIds` after `project_assignments` pull |
| `lib/features/sync/engine/sync_engine.dart` | `SyncEngine._loadSyncedProjectIds` | 1304-1348 | Guard orphan cleaner with `_projectsAdapterCompleted` flag |

### Sync Orchestrator
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/features/sync/application/sync_orchestrator.dart` | `SyncOrchestrator.syncLocalAgencyProjects` | 214-285 | Cancel `_backgroundRetryTimer` at start |
| `lib/features/sync/application/sync_orchestrator.dart` | `SyncOrchestrator._syncWithRetry` | 292-346 | After retry exhaustion, schedule `_backgroundRetryTimer` (60s) |
| `lib/features/sync/application/sync_orchestrator.dart` | `SyncOrchestrator` class | 27 | Add `Timer? _backgroundRetryTimer` field |

### State Management
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/features/projects/presentation/providers/project_provider.dart` | `ProjectProvider.toggleActive` | 531-558 | Add role guard (reject if `!canManageProjects`) |

### Router
| File | Symbol | Line | Change |
|------|--------|------|--------|
| `lib/core/router/app_router.dart` | `AppRouter._buildRouter` redirect | 124-615 | Add `/project/new` guard for `!canManageProjects` |
| `lib/core/router/app_router.dart` | `ScaffoldWithNavBar.build` | 627-747 | Add offline indicator in banner area |

### BaseListProvider Injection (main.dart)
| File | Lines | Change |
|------|-------|--------|
| `lib/main.dart` | 782, 789, 796, 803, 810, 820, 836, 874, 883, 895 | Replace `authProvider.canWrite` with `authProvider.canEditFieldData` (10 sites) |

### Shared Widgets
| File | Symbol | Change |
|------|--------|--------|
| `lib/shared/providers/base_list_provider.dart` | `BaseListProvider.canWrite` | Rename to `canEditFieldData` (or keep name, just update injection) |
| `lib/shared/widgets/view_only_banner.dart` | `ViewOnlyBanner` | Add optional `message` param for Details tab context |
| `lib/features/photos/presentation/providers/photo_provider.dart` | `CanWriteCallback` typedef | Rename or keep (internal) |

### Dashboard
| File | Change |
|------|--------|
| `lib/features/dashboard/presentation/screens/project_dashboard_screen.dart` | Add staleness guard for `selectedProject` |

### Project Setup Screen
| File | Change |
|------|--------|
| `lib/features/projects/presentation/screens/project_setup_screen.dart` | Details tab read-only for inspector, banner shown |

### RLS Migration
| File | Change |
|------|--------|
| `supabase/migrations/20260319200000_tighten_project_rls.sql` (NEW) | Drop+recreate INSERT policy with `is_admin_or_engineer()`, drop+recreate UPDATE policy with `is_admin_or_engineer()`, replace `is_viewer()` body |

## Dependent Files (Callers — 2+ levels)

### Files consuming `canWrite` (grep: ~139 occurrences across 24 files)
- All `BaseListProvider` subclasses (10): LocationProvider, ContractorProvider, EquipmentProvider, BidItemProvider, DailyEntryProvider, PhotoProvider, PersonnelTypeProvider, InspectorFormProvider, CalculatorProvider, TodoProvider
- `lib/main.dart` (10 injection sites)
- `lib/features/projects/presentation/screens/project_list_screen.dart` (multiple)
- Various screen files reading `authProvider.canWrite`

### Files consuming `toggleActive`
- `project_list_screen.dart` (calls it from archive button)

### Files consuming `clearSelectedProject`
- `project_list_screen.dart` (needs to call after removeFromDevice)
- `project_provider.dart` (also called from deleteProject path)

## Test Files
| Test File | What it exercises |
|-----------|-------------------|
| `test/features/projects/presentation/screens/project_list_screen_test.dart` | Project card rendering, canWrite behavior |
| `test/features/projects/presentation/providers/project_provider_tabs_test.dart` | Provider tab logic |
| `test/features/projects/presentation/screens/project_setup_screen_logic_test.dart` | Setup screen logic |
| `test/features/projects/presentation/screens/project_setup_screen_ui_state_test.dart` | Setup screen UI |
| `test/features/sync/presentation/providers/sync_provider_test.dart` | Sync provider |
| `test/features/sync/presentation/widgets/sync_status_icon_test.dart` | Sync status |
| `test/features/sync/presentation/screens/sync_dashboard_screen_test.dart` | Sync dashboard |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Settings screen |
| `test/helpers/mocks/mock_providers.dart` | Mock providers (MockProjectProvider) |

## Dead Code to Remove
| Symbol | File | Reason |
|--------|------|--------|
| `UserRole.canWrite` | `user_role.dart:36` | Replaced by `canManageProjects` + `canEditFieldData` |
| `UserProfile.canWrite` | `user_profile.dart:65` | Delegates to removed role getter |
| `AuthProvider.canWrite` | `auth_provider.dart:183` | Replaced |
| `AuthProvider.canEditProject` | `auth_provider.dart:212` | Dead code (BUG-012) |

## Blast Radius Summary
- **Direct**: 14 files modified, 1 new migration, ~20 symbols changed
- **Dependent**: ~24 files with `canWrite` references (compile-time break)
- **Tests**: 9 test files affected, 15+ new tests needed
- **Cleanup**: 4 dead symbols removed
