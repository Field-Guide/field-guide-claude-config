# Toolbox Constraints

**Feature**: Toolbox (Hub) + Calculator, Forms, Gallery, Todos (Sub-features)
**Scope**: `lib/features/toolbox/` (hub only), `lib/features/calculator/`, `lib/features/forms/`, `lib/features/gallery/`, `lib/features/todos/`

---

## Architecture: Hub + Independent Features

Toolbox is a **navigation hub only**. It contains no business logic, no data layer, and no domain layer.

### Routing Model

`ToolboxHomeScreen` is a grid launcher that routes to four independent features:

| Card | Target Feature | Feature Directory |
|------|---------------|-------------------|
| Forms | Forms list/viewer | `lib/features/forms/` |
| Calculator | Construction calculator | `lib/features/calculator/` |
| Gallery | Photo gallery | `lib/features/gallery/` |
| To-Do's | Task management | `lib/features/todos/` |

Each sub-feature is a **full feature directory** under `lib/features/` with its own `data/`, `domain/`, `presentation/`, and `di/` layers. Toolbox itself has only `presentation/` (the hub screen) and a barrel export.

---

## Hard Rules (Violations = Reject)

### Registry-Based Form Model

Forms use a **registry pattern** — not JSON-schema builders. Each form type registers its screen, PDF filler, calculator, and validator through typed registries.

| Registry | Purpose | Location |
|----------|---------|----------|
| `FormScreenRegistry` | Maps form type to its screen widget builder | `lib/features/forms/data/registries/form_screen_registry.dart` |
| `FormPdfFillerRegistry` | Maps form type to its PDF template filler | `lib/features/forms/data/registries/form_pdf_filler_registry.dart` |
| `FormCalculatorRegistry` | Maps form type to its calculation engine | `lib/features/forms/data/registries/form_calculator_registry.dart` |
| `FormValidatorRegistry` | Maps form type to its validation rules | `lib/features/forms/data/registries/form_validator_registry.dart` |
| `FormQuickActionRegistry` | Maps form type to quick-action shortcuts | `lib/features/forms/data/registries/form_quick_action_registry.dart` |
| `FormInitialDataFactory` | Creates default field values per form type | `lib/features/forms/data/registries/form_initial_data_factory.dart` |

**Adding a new form type** requires:
1. Create the form-specific screen widget, calculator, PDF filler, and validator
2. Create a registrations file (e.g., `mdot_0582b_registrations.dart`) that registers all components
3. Wire registrations into `builtin_form_config.dart`

- No hardcoded form-type switch statements in shared code
- No JSON schema definitions for form structure
- Each form type owns its own UI, validation, calculation, and PDF logic

### Auto-Fill via Service (Not Dedicated Table)

- Auto-fill is handled by `AutoFillService` in `lib/features/forms/data/services/auto_fill_service.dart`
- There is no `toolbox_autofill` table — auto-fill queries historical form responses
- No auto-filling sensitive data (passwords, credentials)

### Form Validation

- All forms validated client-side before submission
- Validation rules are **per-form-type** via `FormValidatorRegistry`, not generic schema rules
- User sees validation errors immediately (no server roundtrip)
- No submitting invalid forms

### Persistence

Each sub-feature uses persistent SQLite storage with full CRUD operations and cloud sync support:
- **Forms**: `inspector_forms`, `form_responses`, `form_exports` tables
- **Calculator**: `calculation_history` table
- **Gallery**: Uses `photos` table (shared with photos feature)
- **Todos**: `todo_items` table

All follow the standard repository/datasource pattern with sync via `change_log` triggers.

---

## Soft Guidelines (Violations = Discuss)

### Performance Targets

- Form load: < 500ms
- Form validation: < 100ms per field
- Auto-fill suggestion: < 200ms
- Form/list rendering: 60fps scroll

### Form State Management

- Use `ChangeNotifier` providers for form state (standard app pattern)
- Form state hashing via `FormStateHasher` for dirty-checking
- `FormPdfService` for PDF export orchestration

### Test Coverage

- Target: >= 85% for registry logic, validators, and calculators
- Lower threshold acceptable for form-specific UI screens (registry handles wiring)

---

## Integration Points

- **Depends on**:
  - `settings` (theme applied to all sub-feature screens)
  - `photos` (gallery shares photo infrastructure)
  - `pdf` (forms export to PDF via `FormPdfService`)
  - `projects` (forms scoped to active project)

- **Required by**:
  - `toolbox` hub (navigation only, no data dependency)

---

## Testing Requirements

- Unit tests: Registry lookups, validators, calculators, auto-fill matching
- Widget tests: Form screens render fields correctly, validation displays errors
- Integration tests: Full form lifecycle (create, fill, validate, export PDF)
- Edge cases: Unregistered form type lookups, validator edge cases, calculator precision

---

## Reference

- **Registrations example**: `lib/features/forms/data/registries/mdot_0582b_registrations.dart`
- **Builtin form config**: `lib/features/forms/data/registries/builtin_form_config.dart`
- **Shared Rules**: `architecture-decisions/data-validation-rules.md`
