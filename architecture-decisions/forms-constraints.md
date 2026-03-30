# Forms Constraints

**Feature**: Form Management (Code-First Inspector Forms)
**Scope**: All code in `lib/features/forms/` and form lifecycle logic

---

## Hard Rules (Violations = Reject)

### Forms Are Developer-Defined, Not User-Defined

- ✗ No user-created form schemas or dynamic field definitions at runtime
- ✓ All forms are developer-defined via code-first registries
- ✓ Adding a new form requires code changes: model definition + registry registrations + PDF template
- ✗ No "form builder" UI that lets users design forms

**Why**: Construction inspection forms (MDOT 0582B, etc.) have strict regulatory layouts, calculation rules, and PDF export requirements that cannot be expressed in a generic schema builder. Each form is a bespoke implementation.

### Registry Pattern

Every form must register its capabilities at app init. The six registries are:

| Registry | Purpose | Typedef / Abstract |
|----------|---------|-------------------|
| `FormScreenRegistry` | Custom UI screen builder per form | `FormScreenBuilder` — returns a `Widget` |
| `FormPdfFillerRegistry` | Maps response data to PDF template fields | `PdfFieldFiller` — returns `Map<String, String>` |
| `FormCalculatorRegistry` | Domain calculations (e.g., density math) | `FormCalculator` abstract — `calculate()`, `calculateProctorChain()`, `emptyTestRow()`, `emptyProctorRow()` |
| `FormValidatorRegistry` | Submission validation rules | `FormValidator` — returns `List<String>` of error messages (empty = valid) |
| `FormInitialDataFactory` | Structured initial `responseData` for new responses | `InitialDataBuilder` — returns `Map<String, dynamic>` |
| `FormQuickActionRegistry` | Quick-action buttons on the form hub | `FormQuickAction` list per form |

**How to register a new form:**

1. Create a `BuiltinFormConfig` entry in `lib/features/forms/data/registries/builtin_forms.dart`
2. Create a registration file (e.g., `mdot_1120_registrations.dart`) that calls `.register()` on each registry
3. Implement the form-specific classes: calculator, validator, PDF filler, screen builder
4. The `BuiltinFormConfig.registerCapabilities` callback wires everything at app init

**Constraints on registries:**
- All registries are **singletons** (`Registry._()` + `static final instance`)
- Registration is **idempotent** — duplicate `register()` calls silently no-op (safe for hot restart)
- Form IDs must match `[a-z0-9_]+` (enforced via assert or ArgumentError)
- Registries have `@visibleForTesting clear()` for test isolation

**Reference**: `lib/features/forms/data/registries/mdot_0582b_registrations.dart` is the canonical example.

### InspectorForm Is Immutable (Template Definition)

- ✓ `InspectorForm` represents a form template (PDF + field definitions + parsing keywords)
- ✓ Built-in forms are seeded at app init from `builtinForms` list via `BuiltinFormConfig.toInspectorForm()`
- ✓ Built-in forms have `isBuiltin = true` and `projectId = null`
- ✗ No modifying built-in form definitions after seeding
- ✓ Non-builtin forms (future) would be project-scoped (`projectId` set)

**Why**: Form templates are regulatory documents; changing the template definition mid-flight would invalidate existing responses.

### FormResponse Lifecycle: Draft to Submitted

- ✓ `FormResponse` states: `open` (draft) → `submitted` → `exported`
- ✓ `open` responses are mutable — editable via `copyWith()`, `withFieldValue()`, `withResponseDataPatch()`
- ✓ `submitted` and `exported` responses are immutable — `isEditable` returns `false`
- ✗ No editing a submitted form response (UI must enforce read-only)
- ✓ Submit and export transitions go through `SubmitFormResponseUseCase`
- ✗ No backward transitions (submitted → open) without explicit undo mechanism

**Why**: Submitted inspection forms are legal documents; immutability after submission prevents audit trail corruption.

### FormResponse Is Project-Scoped

- ✓ Every `FormResponse` has a required `projectId`
- ✓ `formType` identifies which form registry entry this response belongs to (e.g., `"mdot_0582b"`)
- ✓ `entryId` is optional — responses can exist independently or be linked to a daily entry
- ✗ No moving a response between projects after creation

**Why**: Form responses contain project-specific data (job numbers, locations) and must stay scoped.

---

## Soft Guidelines (Violations = Discuss)

### Form Export Contract (PDF Generation)

The PDF export pipeline works as follows:

1. `FormPdfService` receives a `FormPdfData` (response + form template + project metadata)
2. Loads the PDF template bytes from `InspectorForm.templatePath` (asset, file, or remote)
3. Checks `FormPdfFillerRegistry` for a custom filler for this `formType`
   - If found: calls `PdfFieldFiller(responseData, headerData)` to get field-name-to-value map
   - If not found: falls through to generic `fieldDefinitions`-based filling
4. Fills the PDF form fields using Syncfusion PDF library
5. Creates a `FormExport` record (project-scoped, with file path, size, timestamps)

**Key types:**
- `FormPdfData` — bundles `FormResponse`, `InspectorForm`, and project metadata for export
- `FormExport` — tracks the generated PDF file (supports soft delete via `deletedAt`/`deletedBy`)
- `PdfFieldFiller` — `(Map<String, dynamic> responseData, Map<String, dynamic> headerData) → Map<String, String>` (PDF field name → string value)

### AutoFill Service Contract

`AutoFillService` is a stateless utility that builds header auto-fill data from project context:

- Input: named parameters for date, job number, inspector name, cert number, etc.
- Output: `Map<String, String>` with only non-empty values
- Tracks provenance via `FieldMetadata` on `FormResponse.responseMetadata` (source, confidence, isUserEdited)
- Resolves legacy field aliases (e.g., `jobNumber` falls back to `projectNumber`)

**Constraints:**
- ✓ AutoFillService is `const` — no state, no side effects
- ✓ Caller is responsible for passing context data (from project, user profile, etc.)
- ✓ Auto-filled values must be overridable by user (never locked)

### FormResponse Data Structure

- `headerData` — JSON string of header/metadata fields (project number, date, inspector, etc.)
- `responseData` — JSON string of the form body (field values, test rows, proctor rows, etc.)
- `tableRows` — **deprecated**, legacy field; prefer `responseData.test_rows`
- `responseMetadata` — JSON string of per-field `FieldMetadata` for auto-fill provenance tracking

### Performance Targets

- Create form response: < 100ms (local SQLite)
- Calculate fields (e.g., density math): < 50ms
- PDF export: < 3 seconds (template load + fill + write)
- Load form responses for project: < 500ms

### Test Coverage

- Target: >= 85% for form workflows
- Scenarios: Response creation, auto-fill, calculation, validation, submission, PDF export, registry isolation

---

## Integration Points

- **Depends on**:
  - `projects` (responses are project-scoped via `projectId`)
  - `entries` (optional link via `entryId` for daily entry attachments)
  - `pdf` (PDF template filling via Syncfusion)
  - `sync` (forms synced via change_log triggers — `InspectorFormAdapter`, `FormResponseAdapter`)

- **Required by**:
  - `toolbox` (forms hub screen aggregates form types and responses)
  - `entries` (entry detail can show attached form responses)
  - `pdf` (form export generates filled PDFs)
  - `sync` (form data synced to Supabase)

- **Capabilities**:
  - Registry-based extensibility (add new form = new registration file)
  - Auto-fill from project context
  - Per-field metadata tracking (source, confidence, user-edited)
  - Form-specific calculations, validation, and PDF export
  - Quick actions per form type (hub navigation shortcuts)

---

## Reference

- **Registries**: `lib/features/forms/data/registries/`
- **Models**: `lib/features/forms/data/models/` (`InspectorForm`, `FormResponse`, `FormExport`)
- **Services**: `lib/features/forms/data/services/` (`AutoFillService`, `FormPdfService`)
- **Canonical example**: `lib/features/forms/data/registries/mdot_0582b_registrations.dart`
- **Shared Rules**: `architecture-decisions/data-validation-rules.md`
- **Sync Integration**: `architecture-decisions/sync-constraints.md`
