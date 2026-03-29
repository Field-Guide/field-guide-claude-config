## Phase 6: Forms & Entries Domain Layer

> **Goal**: Extract domain interfaces (abstract repository contracts) and use cases for the forms and entries features. Providers switch from depending on concrete repositories to depending on abstract interfaces. Cross-feature imports (e.g., `EntryExportProvider` consuming `FormExportProvider`) go through domain-layer interfaces.

> **Prerequisite**: Phases 1-5 complete (shared domain infrastructure, base use case classes, and other features already migrated).

---

### Sub-phase 6.1: Forms Domain — Repository Interfaces

**Files:**
- Create: `lib/features/forms/domain/domain.dart`
- Create: `lib/features/forms/domain/repositories/form_response_repository_interface.dart`
- Create: `lib/features/forms/domain/repositories/inspector_form_repository_interface.dart`
- Create: `lib/features/forms/domain/repositories/form_export_repository_interface.dart`
- Create: `lib/features/forms/domain/repositories/repositories.dart`
- Modify: `lib/features/forms/data/repositories/form_response_repository.dart`
- Modify: `lib/features/forms/data/repositories/inspector_form_repository.dart`
- Modify: `lib/features/forms/data/repositories/form_export_repository.dart`

**Agent**: `backend-data-layer-agent`

**What to do:**

1. Create `lib/features/forms/domain/repositories/form_response_repository_interface.dart`:
   - Abstract class `IFormResponseRepository` with all public methods from `FormResponseRepository`:
     - `createResponse(FormResponse)`, `getResponseById(String)`, `getResponsesForForm(String)`, `getResponsesForEntry(String)`, `getResponsesForProject(String)`, `getResponsesByStatus(FormResponseStatus)`, `getResponsesByProjectAndStatus(String, FormResponseStatus)`, `updateResponse(FormResponse)`, `submitResponse(String)`, `markAsExported(String)`, `deleteResponse(String)`, `deleteResponsesForEntry(String)`, `getResponseCountForForm(String)`, `getResponseCountForEntry(String)`, `getResponseCountForProject(String)`, `getRecentResponses({required String formId, String? projectId, int limit})`, `getById(String)`, `getAll()`, `save(FormResponse)`, `delete(String)`
   - Return types match existing: `RepositoryResult<FormResponse>`, `RepositoryResult<List<FormResponse>>`, etc.
   - Import models from `lib/features/forms/data/models/models.dart` (models stay in data layer)

2. Create `lib/features/forms/domain/repositories/inspector_form_repository_interface.dart`:
   - Abstract class `IInspectorFormRepository` with:
     - `createForm(InspectorForm)`, `getFormById(String)`, `getFormsForProject(String)`, `getBuiltinForms()`, `updateForm(InspectorForm)`, `deleteForm(String)`, `getAll()`, `getById(String)`, `save(InspectorForm)`, `delete(String)`

3. Create `lib/features/forms/domain/repositories/form_export_repository_interface.dart`:
   - Abstract class `IFormExportRepository` with:
     - `create(FormExport)`, `getById(String)`, `getAll()`, `save(FormExport)`, `delete(String)`, `getByProjectId(String)`, `getByEntryId(String)`, `getByFormResponseId(String)`

4. Make concrete repositories `implements` their interface:
   - `FormResponseRepository implements IFormResponseRepository`
   - `InspectorFormRepository implements IInspectorFormRepository`
   - `FormExportRepository implements IFormExportRepository`
   - Keep existing `implements BaseRepository<T>` — the interface extends or mirrors it

5. Create barrel exports:
   - `lib/features/forms/domain/repositories/repositories.dart` — exports all 3 interfaces
   - `lib/features/forms/domain/domain.dart` — exports `repositories/repositories.dart`

**WHY interfaces live in forms/domain/**: `FormResponseRepository` is consumed by 5 providers across 4 features. The interface in `forms/domain/` is the canonical import point for cross-feature consumers. This avoids circular dependencies — other features depend on the interface, not the concrete data layer.

---

### Sub-phase 6.2: Forms Domain — Use Cases

**Files:**
- Create: `lib/features/forms/domain/usecases/calculate_form_field_use_case.dart`
- Create: `lib/features/forms/domain/usecases/normalize_proctor_row_use_case.dart`
- Create: `lib/features/forms/domain/usecases/export_form_use_case.dart`
- Create: `lib/features/forms/domain/usecases/load_form_responses_use_case.dart`
- Create: `lib/features/forms/domain/usecases/save_form_response_use_case.dart`
- Create: `lib/features/forms/domain/usecases/submit_form_response_use_case.dart`
- Create: `lib/features/forms/domain/usecases/delete_form_response_use_case.dart`
- Create: `lib/features/forms/domain/usecases/load_forms_use_case.dart`
- Create: `lib/features/forms/domain/usecases/manage_documents_use_case.dart`
- Create: `lib/features/forms/domain/usecases/usecases.dart`
- Modify: `lib/features/forms/domain/domain.dart`

**Agent**: `backend-data-layer-agent`

**What to do:**

1. **CalculateFormFieldUseCase** — extracts lines 406-429 from `InspectorFormProvider`:
   - Deps: `IFormResponseRepository`, `FormCalculatorRegistry`
   - Method: `Future<FormResponse?> call(String responseId, String rowType)`
   - Logic: load response, look up calculator from registry, get empty row, append to response data, save via repository
   - This is real business logic (calculator dispatch) — not a pass-through

2. **NormalizeProctorRowUseCase** — extracts lines 370-397 from `InspectorFormProvider`:
   - Deps: `IFormResponseRepository`
   - Method: `Future<FormResponse?> call({required String responseId, required Map<String, dynamic> row})`
   - Logic: normalize weight data, remove chart_type, parse weights_20_10, set wet_soil_mold_g, append to proctor rows, save
   - Mark with `@Deprecated` matching the existing annotation
   - This is real business logic (MDOT 0582B normalization) — not a pass-through

3. **ExportFormUseCase** — extracts logic from `FormExportProvider.exportFormToPdf`:
   - Deps: `IFormResponseRepository`, `IFormExportRepository`, `FormPdfService`
   - Method: `Future<String?> call(String responseId, {String? currentUserId})`
   - Logic: fetch response, generate PDF bytes, save temp file, create FormExport metadata row
   - SEC: Filename generation stays inline (no user input in filename)

4. **Pass-through use cases** (LoadFormResponsesUseCase, SaveFormResponseUseCase, SubmitFormResponseUseCase, DeleteFormResponseUseCase, LoadFormsUseCase):
   - Each wraps a single repository method
   - Deps: the relevant `IFormResponseRepository` or `IInspectorFormRepository`
   - These exist for interface consistency — providers depend on use cases, not repositories

5. **ManageDocumentsUseCase** — extracts logic from `DocumentProvider`:
   - Deps: `IFormResponseRepository`, `DocumentRepository`, `DocumentService`
   - Methods: `loadDocuments(projectId, {formType})`, `loadEntryDocuments(entryId)`, `attachDocument(...)`, `deleteDocument(id)`
   - NOTE: `FormResponseSummary` class moves into this use case file or stays in the provider (it's a presentation mapping). Decision: keep `FormResponseSummary` in presentation since it's a view model.

6. Barrel export `usecases.dart` and update `domain.dart`.

---

### Sub-phase 6.3: Forms Providers — Switch to Use Cases

**Files:**
- Modify: `lib/features/forms/presentation/providers/inspector_form_provider.dart`
- Modify: `lib/features/forms/presentation/providers/form_export_provider.dart`
- Modify: `lib/features/forms/presentation/providers/document_provider.dart`
- Modify: `lib/features/forms/presentation/providers/providers.dart`

**Agent**: `frontend-flutter-specialist-agent`

**What to do:**

1. **InspectorFormProvider** — replace repository + registry deps with use cases:
   - Constructor changes from `(InspectorFormRepository, FormResponseRepository, FormCalculatorRegistry)` to accepting use cases: `LoadFormsUseCase`, `LoadFormResponsesUseCase`, `SaveFormResponseUseCase`, `SubmitFormResponseUseCase`, `DeleteFormResponseUseCase`, `CalculateFormFieldUseCase`, `NormalizeProctorRowUseCase`
   - Pass-through methods (loadFormsForProject, loadResponsesForEntry, etc.) delegate to use cases
   - `appendRow()` delegates to `CalculateFormFieldUseCase`
   - `appendMdot0582bProctorRow()` delegates to `NormalizeProctorRowUseCase`
   - State management (list caching, notifyListeners, canWrite guards) stays in provider
   - Provider still owns `_forms`, `_responses`, `_isLoading`, `_error` state

2. **FormExportProvider** — replace repos + service with use case:
   - Constructor changes to accept `ExportFormUseCase`
   - `exportFormToPdf()` delegates to use case, retains `_isExporting` / `_errorMessage` state management

3. **DocumentProvider** — replace repos + service with use case:
   - Constructor changes to accept `ManageDocumentsUseCase`
   - All methods delegate, provider retains list state + loading flags
   - `FormResponseSummary` stays in this file (view model, not domain)

4. Update barrel export `providers.dart` if needed.

**IMPORTANT**: Do NOT change the public API of any provider. Screens and widgets calling these providers must not need changes. Only constructor signatures change (wired in `main.dart` or provider setup).

---

### Sub-phase 6.4: Entries Domain — Repository Interfaces

**Files:**
- Create: `lib/features/entries/domain/domain.dart`
- Create: `lib/features/entries/domain/repositories/daily_entry_repository_interface.dart`
- Create: `lib/features/entries/domain/repositories/entry_export_repository_interface.dart`
- Create: `lib/features/entries/domain/repositories/document_repository_interface.dart`
- Create: `lib/features/entries/domain/repositories/repositories.dart`
- Modify: `lib/features/entries/data/repositories/daily_entry_repository.dart`
- Modify: `lib/features/entries/data/repositories/entry_export_repository.dart`
- Modify: `lib/features/entries/data/repositories/document_repository.dart`

**Agent**: `backend-data-layer-agent`

**What to do:**

1. Create `IDailyEntryRepository` abstract class with all public methods from `DailyEntryRepository`:
   - All `ProjectScopedRepository<DailyEntry>` methods
   - `getByDate(projectId, date)`, `getByDateRange(projectId, start, end)`, `getByLocationId(locationId)`, `getByStatus(projectId, status)`, `getDatesWithEntries(projectId)`, `updateStatus(id, status)`, `submit(id, signature)`, `deleteByProjectId(projectId)`, `getCountByDate(projectId, date)`, `insertAll(entries)`, `getLastEntrySafetyFields(projectId)`, `getDraftEntries(projectId)`, `batchSubmit(entryIds)`, `undoSubmission(entryId)`

2. Create `IEntryExportRepository` abstract class:
   - `getById(String)`, `getAll()`, `save(EntryExport)`, `delete(String)`, `create(EntryExport)`, `getByProjectId(String)`, `getByEntryId(String)`

3. Create `IDocumentRepository` abstract class:
   - `getById(String)`, `getAll()`, `save(Document)`, `delete(String)`, `create(Document)`, `update(Document)`, `getByProjectId(String)`, `getByEntryId(String)`, `getCountByEntryId(String)`
   - Include `static const allowedFileTypes` or move validation logic to a use case

4. Make concrete repositories implement their interfaces.

5. Barrel exports: `repositories.dart` -> `domain.dart`.

---

### Sub-phase 6.5: Entries Domain — Use Cases

**Files:**
- Create: `lib/features/entries/domain/usecases/submit_entry_use_case.dart`
- Create: `lib/features/entries/domain/usecases/undo_submit_entry_use_case.dart`
- Create: `lib/features/entries/domain/usecases/batch_submit_entries_use_case.dart`
- Create: `lib/features/entries/domain/usecases/export_entry_use_case.dart`
- Create: `lib/features/entries/domain/usecases/load_entries_use_case.dart`
- Create: `lib/features/entries/domain/usecases/manage_entry_use_case.dart`
- Create: `lib/features/entries/domain/usecases/calendar_entries_use_case.dart`
- Create: `lib/features/entries/domain/usecases/usecases.dart`
- Modify: `lib/features/entries/domain/domain.dart`

**Agent**: `backend-data-layer-agent`

**What to do:**

1. **SubmitEntryUseCase**:
   - Deps: `IDailyEntryRepository`
   - Method: `Future<RepositoryResult<void>> call(String id, String signature)`
   - Delegates to `repository.submit(id, signature)`

2. **UndoSubmitEntryUseCase**:
   - Deps: `IDailyEntryRepository`
   - Method: `Future<RepositoryResult<void>> call(String entryId)`
   - Delegates to `repository.undoSubmission(entryId)`

3. **BatchSubmitEntriesUseCase**:
   - Deps: `IDailyEntryRepository`
   - Method: `Future<RepositoryResult<DateTime>> call(List<String> entryIds)`
   - Delegates to `repository.batchSubmit(entryIds)`

4. **ExportEntryUseCase** — extracts logic from `EntryExportProvider.exportAllFormsForEntry`:
   - Deps: `IDailyEntryRepository`, `IEntryExportRepository`, `IFormResponseRepository` (cross-feature import from forms/domain/), `ExportFormUseCase` (cross-feature import from forms/domain/)
   - Method: `Future<List<String>> call(String entryId, {String? currentUserId})`
   - Logic: load entry, load form responses for entry, delegate each to ExportFormUseCase, create EntryExport metadata row
   - **Cross-feature**: imports `IFormResponseRepository` from `forms/domain/repositories/` and `ExportFormUseCase` from `forms/domain/usecases/`

5. **Pass-through use cases** (LoadEntriesUseCase, ManageEntryUseCase, CalendarEntriesUseCase):
   - Wrap repository methods for CRUD, date queries, calendar markers
   - CalendarEntriesUseCase: `getDatesWithEntries(projectId)`, `getByDate(projectId, date)`

6. Barrel export `usecases.dart` and update `domain.dart`.

---

### Sub-phase 6.6: Entries Providers — Switch to Use Cases

**Files:**
- Modify: `lib/features/entries/presentation/providers/daily_entry_provider.dart`
- Modify: `lib/features/entries/presentation/providers/entry_export_provider.dart`
- Modify: `lib/features/entries/presentation/providers/calendar_format_provider.dart`
- Modify: `lib/features/entries/presentation/providers/providers.dart`

**Agent**: `frontend-flutter-specialist-agent`

**What to do:**

1. **DailyEntryProvider** — replace `DailyEntryRepository` with use cases:
   - Constructor changes: accept `LoadEntriesUseCase`, `ManageEntryUseCase`, `SubmitEntryUseCase`, `UndoSubmitEntryUseCase`, `BatchSubmitEntriesUseCase`, `CalendarEntriesUseCase`
   - NOTE: `DailyEntryProvider extends BaseListProvider<DailyEntry, DailyEntryRepository>`. The generic parameter `R extends ProjectScopedRepository<T>` must now accept the interface: `BaseListProvider<DailyEntry, IDailyEntryRepository>` — verify `IDailyEntryRepository extends ProjectScopedRepository<DailyEntry>` in the interface definition (sub-phase 6.4)
   - All state management (date maps, pagination, selected date) stays in provider
   - Pass-through methods delegate to use cases

2. **EntryExportProvider** — replace deps with use case:
   - Constructor changes to accept `ExportEntryUseCase`
   - `exportAllFormsForEntry()` delegates to use case
   - Retains `_isExporting`, `_exportedPaths`, `_errorMessage` state
   - **Removes direct dependency on `FormExportProvider`** — cross-feature coordination now handled by `ExportEntryUseCase` in the domain layer

3. **CalendarFormatProvider** — no domain dependencies:
   - This provider has zero repository deps (pure UI state + SharedPreferences)
   - No use cases needed. Leave as-is.
   - Confirm in barrel export it's still exported

4. Update barrel export `providers.dart`.

**Controllers stay in presentation**: `EntryEditingController`, `ContractorEditingController`, `PhotoAttachmentManager`, `FormAttachmentManager`, `PdfDataBuilder` are UI coordination logic. They remain in `presentation/controllers/` unchanged.

---

### Sub-phase 6.7: Provider Wiring Update

**Files:**
- Modify: `lib/main.dart` (or wherever providers are registered with `MultiProvider`/`ChangeNotifierProvider`)

**Agent**: `frontend-flutter-specialist-agent`

**What to do:**

1. Update provider registration to construct use cases and inject them:
   - `InspectorFormProvider` now takes use cases instead of repositories
   - `FormExportProvider` now takes `ExportFormUseCase`
   - `DocumentProvider` now takes `ManageDocumentsUseCase`
   - `DailyEntryProvider` now takes entry use cases
   - `EntryExportProvider` now takes `ExportEntryUseCase`

2. **Ordering constraint preserved**: `FormExportProvider` (or its underlying `ExportFormUseCase`) must still be created before `EntryExportProvider` / `ExportEntryUseCase`. Since `ExportEntryUseCase` takes `ExportFormUseCase` as a constructor param (not `context.read`), the ordering is now compile-time enforced instead of runtime-dependent.

3. Verify `CalendarFormatProvider` registration unchanged (no deps to update).

---

### Sub-phase 6.8: Tests — Domain Layer

**Files:**
- Create: `test/features/forms/domain/usecases/calculate_form_field_use_case_test.dart`
- Create: `test/features/forms/domain/usecases/normalize_proctor_row_use_case_test.dart`
- Create: `test/features/forms/domain/usecases/export_form_use_case_test.dart`
- Create: `test/features/entries/domain/usecases/submit_entry_use_case_test.dart`
- Create: `test/features/entries/domain/usecases/undo_submit_entry_use_case_test.dart`
- Create: `test/features/entries/domain/usecases/batch_submit_entries_use_case_test.dart`
- Create: `test/features/entries/domain/usecases/export_entry_use_case_test.dart`

**Agent**: `qa-testing-agent`

**What to do:**

1. **CalculateFormFieldUseCase tests** (highest value — real business logic):
   - Mock `IFormResponseRepository` and `FormCalculatorRegistry`
   - Test: returns null when response not found
   - Test: returns null when no calculator registered for form type
   - Test: appends proctor_rows via emptyProctorRow()
   - Test: appends test_rows via emptyTestRow()
   - Test: returns null for unknown rowType

2. **NormalizeProctorRowUseCase tests** (highest value — MDOT-specific logic):
   - Test: removes chart_type from row
   - Test: trims and filters empty weights_20_10 values
   - Test: sets wet_soil_mold_g from last weight value
   - Test: handles empty weights list
   - Test: appends to existing proctor rows

3. **ExportFormUseCase tests**:
   - Mock `IFormResponseRepository`, `IFormExportRepository`, `FormPdfService`
   - Test: returns null when response not found
   - Test: returns null when PDF generation fails
   - Test: creates FormExport metadata row on success
   - Test: returns saved file path on success

4. **Entry use case tests** (submit, undo, batch):
   - Mock `IDailyEntryRepository`
   - Test: delegates to repository correctly
   - Test: batch submit with empty list returns failure
   - Test: undo on non-submitted entry returns failure

5. **ExportEntryUseCase tests** (cross-feature):
   - Mock `IDailyEntryRepository`, `IEntryExportRepository`, `IFormResponseRepository`, `ExportFormUseCase`
   - Test: returns empty list when entry not found
   - Test: exports each form response via ExportFormUseCase
   - Test: creates EntryExport metadata row with first PDF path

6. **Existing tests must still pass**:
   - `test/features/forms/data/repositories/form_export_repository_test.dart`
   - `test/features/forms/data/repositories/form_response_repository_test.dart`
   - `test/features/entries/data/repositories/document_repository_test.dart`
   - `test/features/entries/data/repositories/entry_export_repository_test.dart`
   - `test/features/entries/presentation/providers/calendar_format_provider_test.dart`

**Verification commands:**
```
pwsh -Command "flutter analyze"
pwsh -Command "flutter test"
```

---

### Dependency Graph

```
Sub-phase 6.1 (forms repo interfaces)
    │
    ├──► Sub-phase 6.2 (forms use cases) ──► Sub-phase 6.3 (forms providers)
    │                                                │
    │                                                ▼
    │                                        Sub-phase 6.7 (wiring)
    │                                                ▲
Sub-phase 6.4 (entries repo interfaces)              │
    │                                                │
    ├──► Sub-phase 6.5 (entries use cases) ─► Sub-phase 6.6 (entries providers)
    │         │
    │         └── depends on 6.1 + 6.2 (cross-feature: IFormResponseRepository, ExportFormUseCase)
    │
    └──► Sub-phase 6.8 (tests) — runs after 6.7

Parallelizable: 6.1 and 6.4 can run in parallel.
Parallelizable: 6.2 and 6.4 can run in parallel (6.2 only needs 6.1).
Sequential: 6.5 depends on 6.1 + 6.2 + 6.4.
Sequential: 6.3 depends on 6.2; 6.6 depends on 6.5.
Sequential: 6.7 depends on 6.3 + 6.6.
Sequential: 6.8 depends on 6.7.
```

### File Count Summary

| Sub-phase | New | Modified | Agent |
|-----------|-----|----------|-------|
| 6.1 | 5 | 3 | backend-data-layer-agent |
| 6.2 | 10 | 1 | backend-data-layer-agent |
| 6.3 | 0 | 4 | frontend-flutter-specialist-agent |
| 6.4 | 5 | 3 | backend-data-layer-agent |
| 6.5 | 8 | 1 | backend-data-layer-agent |
| 6.6 | 0 | 4 | frontend-flutter-specialist-agent |
| 6.7 | 0 | 1 | frontend-flutter-specialist-agent |
| 6.8 | 7 | 0 | qa-testing-agent |
| **Total** | **35** | **17** | |
