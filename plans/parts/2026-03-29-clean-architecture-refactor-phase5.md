## Phase 5: Projects Domain Layer (Second Heaviest)

Break `ProjectProvider` (800 lines, 54 symbols) into use cases. Fix `ProjectSetupScreen` and `ProjectProvider` layer violations (6 total). `ProjectProvider` stays as state holder, delegates to use cases. Raw DB queries move into repository methods first, then use cases wrap those.

### Sub-phase 5.1: Create SyncedProjectRepository and Extend ProjectAssignmentRepository

**Files:**
- `lib/features/projects/data/repositories/synced_project_repository.dart` (NEW)
- `lib/features/projects/data/repositories/project_assignment_repository.dart` (EDIT)
- `lib/features/projects/data/repositories/project_repository.dart` (EDIT)
- `lib/features/projects/data/repositories/repositories.dart` (EDIT — barrel export)

**Agent**: backend-data-layer-agent

**What:**

1. **Create `SyncedProjectRepository`** with these methods extracted from `ProjectProvider` raw DB queries:
   - `getAll()` — returns all synced_projects rows (used by `fetchRemoteProjects` line 697)
   - `getUnassignedAtMap()` — returns `Map<String, String?>` of project_id -> unassigned_at (used by `loadAssignments` line 237-241)
   - `enroll(String projectId)` — insert into synced_projects with synced_at timestamp (used by `enrollProject` line 255-268 AND `project_setup_screen.dart` line 985-993)
   - `unenroll(String projectId)` — delete from synced_projects (used by `unenrollProject` line 274-285)

2. **Add to `ProjectRepository`:**
   - `getCreatedByUserId(String projectId)` — queries `projects` table for `created_by_user_id` column only (used by `deleteProject` auth check, line 555-560). Returns `String?`.
   - `getMetadataByCompanyId(String companyId)` — returns lightweight project rows with only `id, name, project_number, company_id, is_active, updated_at` columns (used by `fetchRemoteProjects` line 702-707). Returns `List<Map<String, dynamic>>` or a dedicated lightweight model.

3. **Update barrel export** `repositories.dart` to include `SyncedProjectRepository`.

**Verification:** `pwsh -Command "flutter analyze"` — no new warnings.

**Why these groupings:**
- `synced_projects` is a distinct local-only table tracking device enrollment, not part of the `projects` table. It deserves its own repository.
- `getCreatedByUserId` belongs in `ProjectRepository` since it queries the `projects` table.
- `getMetadataByCompanyId` belongs in `ProjectRepository` as a lightweight variant of existing `getByCompanyId`.

---

### Sub-phase 5.2: Create CompanyMembersRepository

**Files:**
- `lib/features/projects/data/repositories/company_members_repository.dart` (NEW)
- `lib/features/projects/data/repositories/repositories.dart` (EDIT — barrel export)
- `lib/features/projects/data/models/assignable_member.dart` (NEW)

**Agent**: backend-data-layer-agent

**What:**

1. **Extract `AssignableMember` model** from `project_assignment_provider.dart` (line 9-17) into a standalone model file at `lib/features/projects/data/models/assignable_member.dart`. The class in the provider file becomes a re-export or import from the model file. This is needed because the model will be used by both the repository and the provider.

2. **Create `CompanyMembersRepository`** with one method:
   - `getApprovedMembers(String companyId)` — wraps the Supabase query currently at `project_setup_screen.dart:181-196`:
     ```
     Supabase.instance.client.from('user_profiles').select('id, display_name, role')
       .eq('company_id', companyId).eq('status', 'approved')
     ```
   - Returns `List<AssignableMember>`.
   - Handles safe casting (the FIX 5 pattern from line 190).

3. **Update barrel export.**

**Verification:** `pwsh -Command "flutter analyze"` — no new warnings.

**Why a separate repo:** `user_profiles` is an auth-domain table accessed via Supabase (not local SQLite). It doesn't fit in `ProjectRepository` or `ProjectAssignmentRepository`. A small dedicated repository keeps the Supabase import isolated from presentation.

---

### Sub-phase 5.3: Create Use Cases

**Files:**
- `lib/features/projects/domain/use_cases/delete_project_use_case.dart` (NEW)
- `lib/features/projects/domain/use_cases/load_assignments_use_case.dart` (NEW)
- `lib/features/projects/domain/use_cases/fetch_remote_projects_use_case.dart` (NEW)
- `lib/features/projects/domain/use_cases/load_company_members_use_case.dart` (NEW)

**Agent**: backend-data-layer-agent

**What:**

1. **`DeleteProjectUseCase`**
   - Dependencies: `ProjectRepository`, `DatabaseService`, `SoftDeleteService` factory or provider
   - Method: `Future<DeleteProjectResult> call({required String projectId, required String currentUserId, required bool isAdmin})`
   - Extracts lines 542-620 from `ProjectProvider.deleteProject`:
     - Step 1: Auth check via `projectRepository.getCreatedByUserId(projectId)` (replaces raw DB query at line 555)
     - Step 2: Supabase RPC `admin_soft_delete_project` (moves the `Supabase.instance.client.rpc` call from line 585 into the use case)
     - Step 3: Local cascade via `SoftDeleteService.cascadeSoftDeleteProject`
   - Returns a result object with `success`, `error`, and `rpcSucceeded` fields
   - **CRITICAL:** Preserve exact authorization logic and cascade order. The RPC must fire BEFORE local cascade.

2. **`LoadAssignmentsUseCase`**
   - Dependencies: `ProjectAssignmentRepository`, `SyncedProjectRepository`
   - Method: `Future<AssignmentState> call(String userId)`
   - Extracts lines 221-249 from `ProjectProvider.loadAssignments`:
     - Gets assigned project IDs via `projectAssignmentRepository.getAssignedProjectIds(userId)` (already exists!)
     - Gets synced project unassigned_at map via `syncedProjectRepository.getUnassignedAtMap()`
   - Returns `AssignmentState` record/class with `Set<String> assignedProjectIds` and `Map<String, String?> syncedProjectUnassignedAt`

3. **`FetchRemoteProjectsUseCase`**
   - Dependencies: `ProjectRepository`, `SyncedProjectRepository`
   - Method: `Future<FetchRemoteProjectsResult> call(String companyId)`
   - Extracts lines 680-745 from `ProjectProvider.fetchRemoteProjects`:
     - Reloads local projects via `projectRepository.getByCompanyId(companyId)`
     - Gets enrolled IDs via `syncedProjectRepository.getAll()` -> map to set
     - Gets all project metadata via `projectRepository.getMetadataByCompanyId(companyId)`
     - Computes remote-only projects (all minus enrolled)
   - Returns result with `List<Project> localProjects`, `List<Project> remoteProjects`, `Set<String> allKnownProjectIds`

4. **`LoadCompanyMembersUseCase`**
   - Dependencies: `CompanyMembersRepository`
   - Method: `Future<List<AssignableMember>> call(String companyId)`
   - Thin wrapper — but exists so `ProjectSetupScreen` doesn't import a repository directly
   - Can add caching later (company members rarely change mid-session)

**Verification:** `pwsh -Command "flutter analyze"` — no new warnings.

---

### Sub-phase 5.4: Rewire ProjectProvider to Use Cases

**Files:**
- `lib/features/projects/presentation/providers/project_provider.dart` (EDIT)

**Agent**: backend-data-layer-agent

**What:**

1. **Add use case dependencies** to `ProjectProvider` constructor:
   - `DeleteProjectUseCase`
   - `LoadAssignmentsUseCase`
   - `FetchRemoteProjectsUseCase`
   - All optional with late initialization or nullable, to avoid breaking existing construction sites before Phase 5.5 wires DI.

2. **Replace `deleteProject` body** (lines 542-620):
   - Delegate to `DeleteProjectUseCase.call(projectId: id, currentUserId: currentUserId, isAdmin: isAdmin)`
   - Keep only the state management part: remove from `_projects`, clear `_selectedProject`, clear settings, set `_isLoading`/`_error`, `notifyListeners()`
   - **Remove:** `import 'package:supabase_flutter/supabase_flutter.dart'` (if no other usage remains)
   - **Remove:** `import 'package:construction_inspector/services/soft_delete_service.dart'`

3. **Replace `loadAssignments` body** (lines 221-249):
   - Delegate to `LoadAssignmentsUseCase.call(userId)`
   - Assign result fields to `_assignedProjectIds` and `_syncedProjectUnassignedAt`
   - Call `_buildMergedView()` and `notifyListeners()`
   - **Remove:** `DatabaseService dbService` parameter — use case carries its own deps
   - **BREAKING CHANGE:** All callers of `loadAssignments` must be updated (Sub-phase 5.5)

4. **Replace `fetchRemoteProjects` body** (lines 680-745):
   - Delegate to `FetchRemoteProjectsUseCase.call(_companyId!)`
   - Assign result fields to `_projects`, `_remoteProjects`, `_allKnownProjectIds`
   - Call `_buildMergedView()` and `notifyListeners()`

5. **Replace `enrollProject` and `unenrollProject`** (lines 253-286):
   - Delegate to `SyncedProjectRepository.enroll()` and `.unenroll()`
   - Remove `DatabaseService dbService` parameter
   - **BREAKING CHANGE:** All callers must be updated (Sub-phase 5.5)

6. **Remove `_databaseService` field** if no remaining direct DB access.

7. **Remove `import 'package:sqflite/sqflite.dart'`** if no remaining usage.

**Verification:** `pwsh -Command "flutter analyze"` — expect errors from callers not yet updated (fixed in 5.5).

**Net effect on ProjectProvider:** ~250 lines removed (deleteProject: ~80, loadAssignments: ~30, fetchRemoteProjects: ~65, enrollProject: ~15, unenrollProject: ~15, imports/fields: ~15). Provider drops from ~800 to ~550 lines. Remaining code is pure state management + UI getters.

---

### Sub-phase 5.5: Rewire ProjectSetupScreen and Fix All Callers

**Files:**
- `lib/features/projects/presentation/screens/project_setup_screen.dart` (EDIT)
- `lib/features/projects/presentation/providers/project_assignment_provider.dart` (EDIT)
- `lib/main.dart` (EDIT — DI wiring)
- Any other callers of `loadAssignments`, `enrollProject`, `unenrollProject` (search required)

**Agent**: frontend-flutter-specialist-agent

**What:**

1. **Fix `project_setup_screen.dart` line 181-196** (Supabase direct query):
   - Replace `Supabase.instance.client.from('user_profiles').select(...)` with `LoadCompanyMembersUseCase.call(companyId)`
   - Inject `LoadCompanyMembersUseCase` via `context.read<>()` or pass through provider
   - Remove `import 'package:supabase_flutter/supabase_flutter.dart'` from this file

2. **Fix `project_setup_screen.dart` line 985-993** (raw DB insert into synced_projects):
   - Replace `db.insert('synced_projects', ...)` with `context.read<ProjectProvider>().enrollProject(projectId)`
   - Or call `SyncedProjectRepository.enroll()` directly via provider
   - Remove `import 'package:sqflite/sqflite.dart'` from this file if no other usage

3. **Update `project_assignment_provider.dart`:**
   - Change `AssignableMember` class to import from `data/models/assignable_member.dart`
   - Keep re-export for backward compatibility if other files import it from here

4. **Update all callers** of `ProjectProvider.loadAssignments(userId, dbService)`:
   - Search for `.loadAssignments(` across codebase
   - Update signature to `.loadAssignments(userId)` (no more dbService param)

5. **Update all callers** of `ProjectProvider.enrollProject(projectId, dbService)` and `.unenrollProject(projectId, dbService)`:
   - Search for `.enrollProject(` and `.unenrollProject(` across codebase
   - Update signature to `.enrollProject(projectId)` (no more dbService param)

6. **Wire DI in `main.dart`:**
   - Create `SyncedProjectRepository` and `CompanyMembersRepository` instances
   - Create use case instances with their dependencies
   - Pass use cases to `ProjectProvider` constructor
   - Register `LoadCompanyMembersUseCase` as a provider (or make accessible through existing provider)

**Verification:** `pwsh -Command "flutter analyze"` — zero errors/warnings.

---

### Sub-phase 5.6: Update Existing Tests

**Files:**
- `test/features/projects/data/repositories/project_repository_test.dart` (EDIT)
- `test/features/projects/presentation/providers/project_provider_merged_view_test.dart` (EDIT)
- `test/features/projects/presentation/providers/project_provider_tabs_test.dart` (EDIT)
- `test/features/projects/presentation/providers/project_assignment_provider_test.dart` (EDIT)
- `test/features/projects/domain/use_cases/delete_project_use_case_test.dart` (NEW)
- `test/features/projects/domain/use_cases/load_assignments_use_case_test.dart` (NEW)
- `test/features/projects/domain/use_cases/fetch_remote_projects_use_case_test.dart` (NEW)
- `test/features/projects/data/repositories/synced_project_repository_test.dart` (NEW)

**Agent**: qa-testing-agent

**What:**

1. **Fix existing `project_provider_merged_view_test.dart`:**
   - Update `ProjectProvider` construction to pass use case mocks
   - Update `loadAssignments` calls to new signature (no dbService)
   - Ensure all existing assertions still pass

2. **Fix existing `project_provider_tabs_test.dart`:**
   - Same pattern — update constructor and method signatures

3. **Fix existing `project_assignment_provider_test.dart`:**
   - Update `AssignableMember` import path if changed

4. **New `delete_project_use_case_test.dart`:**
   - Test authorization: creator can delete, non-creator non-admin cannot
   - Test RPC failure path: local cascade still runs, rpcSucceeded=false
   - Test project not found: returns error
   - Test successful path: RPC + cascade both fire in order
   - Mock: `ProjectRepository`, `SoftDeleteService`, Supabase client (or abstract the RPC call)

5. **New `load_assignments_use_case_test.dart`:**
   - Test returns correct assigned IDs and unassigned_at map
   - Test empty state (no assignments, no synced_projects)

6. **New `fetch_remote_projects_use_case_test.dart`:**
   - Test merging: enrolled projects excluded from remote list
   - Test allKnownProjectIds includes both enrolled and unenrolled
   - Test null updated_at handling (fallback to DateTime.now)

7. **New `synced_project_repository_test.dart`:**
   - Test enroll/unenroll CRUD
   - Test getAll and getUnassignedAtMap

**Verification:** `pwsh -Command "flutter test"` — all tests pass (existing + new).

---

### Layer Violation Resolution Summary

| # | Location | Violation | Fixed In | Resolution |
|---|----------|-----------|----------|------------|
| 1 | `project_provider.dart:223` | Raw DB query on project_assignments | 5.4 | Delegates to `LoadAssignmentsUseCase` -> `ProjectAssignmentRepository.getAssignedProjectIds()` (already exists) |
| 2 | `project_provider.dart:255` | Raw DB query on synced_projects | 5.4 | Delegates to `SyncedProjectRepository.enroll()` / `.unenroll()` / `.getUnassignedAtMap()` |
| 3 | `project_provider.dart:275` | Raw DB query on projects | 5.4 | Delegates to `FetchRemoteProjectsUseCase` -> `ProjectRepository.getMetadataByCompanyId()` |
| 4 | `project_provider.dart:585` | Direct `Supabase.instance.client.rpc()` | 5.3/5.4 | Moved into `DeleteProjectUseCase` |
| 5 | `project_setup_screen.dart:181` | Direct `Supabase.instance.client.from('user_profiles').select()` | 5.5 | Replaced with `LoadCompanyMembersUseCase` -> `CompanyMembersRepository` |
| 6 | `project_setup_screen.dart:985` | `dbService.database` raw insert into synced_projects | 5.5 | Replaced with `SyncedProjectRepository.enroll()` via provider |

### Risk Notes

- **DeleteProjectUseCase is security-critical.** The authorization check (creator OR admin) and the cascade order (RPC before local) must be preserved exactly. Review the use case test coverage before merging.
- **Supabase RPC abstraction:** `DeleteProjectUseCase` will still import `supabase_flutter` directly for the RPC call. A future phase could abstract this behind a `ProjectRemoteService` interface, but that is out of scope for Phase 5.
- **Breaking signature changes** in `loadAssignments`, `enrollProject`, `unenrollProject` require a codebase-wide search for all callers. Sub-phase 5.5 must not skip any.
- **`AssignableMember` extraction** may break imports in files that import it from `project_assignment_provider.dart`. The barrel export must maintain backward compatibility.
