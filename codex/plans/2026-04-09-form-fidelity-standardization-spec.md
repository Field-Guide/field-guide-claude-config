# 2026-04-09 Form Export Fidelity + Shared Workflow Standardization Spec

## Summary

Standardize the forms stack around one reusable, open, section-based workflow
shell, using 0582B's openness as the interaction baseline, while fixing the
two current fidelity problems in parallel:

- IDR / daily-entry export fidelity is still wrong against the canonical PDF.
- MDOT 1126 has both export/capture drift and a one-off wizard UX that no
  longer fits the direction of the app.

Locked intent:

- Future forms use a shared shell, with freedom only where the form genuinely
  needs it.
- The default feel should be more like 0582B: open, visible, section-driven.
- Typed-only validated signatures are the standard.
- The Forms gallery should be split by mode, not one dense mixed list.
- 1174R Concrete should be phased into the same rollout, after the shell is
  proven on IDR/1126.

## Progress Snapshot

Closed in source and verification on 2026-04-09:

- IDR canonical export fidelity hardening is landed and green:
  - day autofill now writes the canonical field correctly
  - contractor/equipment row ordering is deterministic
  - equipment checkbox coverage is mapped and tested
- MDOT 1126 now uses the shared open workflow shell with visible sections for:
  - Header
  - Inspection Dates & Precipitation
  - Type of Control / Location / Corrective Action
  - Remarks
  - Inspector Signature
- MDOT 1126 nightly intent correction is now closed in source and local
  verification:
  - user-facing weekly reporting period is no longer exposed in the shell
  - user-facing average/high temperature inputs are no longer exposed
  - new 1126 drafts now open with a visible starter measure row instead of an
    empty measures list
  - saved 1126 responses now normalize legacy measure payloads into the
    explicit canonical keys:
    - `measure_type`
    - `location_station`
  - filler, validator, carry-forward, and UI all preserve backward
    compatibility with old `description` / `location` rows
  - header labels now match the intended 1126 terminology:
    - storm water operator number
    - comprehensive training number
  - workflow-only daily-entry attachment is no longer counted as a numbered PDF
    section; it now lives in a trailing workflow tools card
- Forms gallery is now split into `Create / Saved / History` inside the
  existing `/forms` route.
- MDOT 1174R is now a shipped runtime builtin form with the canonical asset
  path `assets/templates/forms/mdot_1174r_form.pdf`.
- MDOT 1174R canonical template inventory is now locked by regression test at
  `226` named fields.
- MDOT 1174R now has a real shared-shell editor, seeded initial-data schema,
  canonical PDF filler, project-known autofill, and mapping-matrix coverage.
- MDOT 1174R now follows the same section-vs-workflow pattern as 1126:
  - numbered sections stay aligned to the PDF
  - daily-entry attachment lives in a trailing workflow tools card instead of
    masquerading as a paper-form section
- Canonical template inventory locking is now even across the shipped runtime
  PDFs instead of stopping at 1174R:
  - IDR exact runtime field count is locked at `179`
  - MDOT 1126 exact runtime field count is locked at `62`
  - MDOT 0582B exact runtime field count is locked at `269`
  - MDOT 1174R remains locked at `226`
- MDOT 1174R now uses the shared relevant-date seam for filename/attach
  behavior:
  - `report_date` is now treated as the relevant form date when
    `inspection_date` is absent
  - the generic attach step now uses the resolved form date instead of
    hardcoding `inspection_date`
- MDOT 1126 export now matches the latest product intent more closely:
  - `WEEKLY REPORTING PERIOD` is no longer populated
  - `AVERAGE TEMPERATURE` is no longer populated
  - `HIGH TEMPERATURE` is no longer populated

Closed with S21 proof on 2026-04-09:

- Forms gallery `Create` mode clearly shows 0582B, 1126, and 1174R workflows.
- Forms gallery `Saved` mode groups editable responses by form type.
- Forms gallery `History` mode isolates export history from editable work.
- MDOT 1126 shared shell renders correctly on-device with the new open
  section-based workflow.
- MDOT 1126 preview still opens the shared PDF preview on-device.
- MDOT 1126 export still routes through the shared attach/export decision on
  the live build.
- MDOT 1174R launches from the gallery into the runtime form surface on-device.

Still open against this spec:

- broader MDOT 1126 / SESC workflow hardening beyond the shell refit
- MDOT 1174R still needs direct S21 fill/edit/preview/export/attach proof on
  the fresh shared-shell implementation
- weekly SESC reminder `resume draft` still needs direct S21 proof in the real
  reminder state even though source/test coverage is now closed
- the latest local source/test slice is green, but fresh S21 verification is
  still blocked because `adb devices -l` currently returns no attached device
- the current device-verification sweep is temporarily blocked by ADB/device
  disconnect; local source/test work continued, but fresh S21 proof is still
  required for the remaining open items

## Key Changes

### 1. Canonical export fidelity closure

#### IDR / daily-entry export

- Keep `assets/templates/idr_template.pdf` as the canonical runtime template
  and verify it against the clean source PDF already identified.
- Correct the IDR writer against the real AcroForm layout, with these
  corrections:
  - treat day as an autofilled text field, not a user-facing dropdown
    interaction
  - remove any planned product work around the record drawings uploaded
    checkbox; leave it unused/off
  - write to the real signature target, not placeholder legacy fields
  - add deterministic contractor/equipment row ordering before field assignment
  - map equipment-use visibility honestly, including the real checkbox fields
    where the template expects them
  - clear unused rows and checkbox states cleanly
- Extend tests to prove:
  - canonical field inventory is preserved
  - day autofill is correct
  - contractor/equipment row ordering is stable
  - checkbox state matches selected equipment
  - exported PDF remains editable

#### MDOT 1126 export

- Audit `assets/templates/forms/mdot_1126_form.pdf` the same way, but treat the
  main issue as missing capture surface, not checkbox complexity.
- Keep `fillMdot1126PdfFields` as the export seam, but align it to the real
  template and the actual UI contract.
- Expose and validate the fields the filler already expects or should expect:
  - control section
  - report number
  - route/location
  - construction engineer / maintenance coordinator
  - storm water operator number
  - comprehensive training number
  - date of last inspection
  - precipitation summary
  - type of SESC measure
  - location/station
  - remarks
- Leave weekly reporting period blank for now instead of surfacing it in the
  shell; if product later restores it, treat that as a new explicit
  requirement.
- Keep winter-only average/high temperature fields out of the user-facing shell
  unless a future product requirement restores them.
- Verify signature stamping targets the real 1126 signature area and stays
  editable after export.
- Remove remaining drawn-signature assumptions from 1126 specs/comments/tests.

#### 1174R Concrete

- Add `1174R Concrete.pdf` to the canonical template inventory now.
- Runtime registration landed on 2026-04-09:
  - canonical asset shipped as `assets/templates/forms/mdot_1174r_form.pdf`
  - builtin id `mdot_1174r`
  - seeded as `MDOT 1174R Concrete`
  - shared-shell editor, seeded schema, and PDF filler are now landed
- Perform the same first-pass audit:
  - field inventory
  - field types
  - header/row/remarks/closeout seams
- 1174 now follows the shared workflow shell with sections for:
  - Header & Placement Details
  - Temperatures - Air - Slump
  - QA Cylinder Table
  - Item / Quantity Table
  - Remarks / Computations
  - Closeout
- 1174 attachment now lives in the shared workflow tools area rather than the
  numbered PDF section list

### 2. Shared form workflow shell

Create one reusable form workflow shell for non-pay-app forms.

#### Shared shell contract

- Common shell owns:
  - app bar/title
  - dirty-state / leave-confirm handling
  - section navigation
  - section completion/error badges
  - preview/export status/actions
  - attachment status
  - typed-signature status
- Form-specific logic lives inside pluggable section widgets and controllers,
  not bespoke top-level screens.

#### Shared building blocks

- Standardize reusable section blocks for:
  - header/project metadata
  - context/date/report metadata
  - repeatable rows/tables
  - remarks/notes
  - typed signature
  - attach-to-entry
  - export state/actions
- Add a section-definition model:
  - section id
  - label
  - completion state
  - error state
  - widget builder
- Keep preview/export/attach mutations behind the existing approved owners.

### 3. MDOT 1126 refit

Move 1126 from a narrow forced-step wizard to the shared open editor model.

#### New 1126 shape

- Refit 1126 into visible sections:
  - Header
  - Inspection context
  - Rainfall
  - SESC measures
  - Remarks
  - Signature
  - Attach / export
- Preserve weekly-specific behavior:
  - carry-forward
  - report numbering
  - date-of-last-inspection logic
  - reminder anchoring
- But surface that behavior inside visible sections, not hidden step
  transitions.

#### Product behavior

- First-week and carry-forward fills still work, but in the same shell.
- Attach/create-entry behavior remains shared and entry-owned.
- Editing a signed 1126 still clears the signature immediately.
- 1126 should no longer feel like a different product from 0582B.

### 4. Forms gallery redesign

Replace the current dense mixed gallery with a split-by-mode surface.

#### Modes

- `Create`
  - form-type cards first
  - easy to start a new workflow
- `Saved`
  - editable responses grouped by form type
  - lighter cards, less vertical intimidation
- `History`
  - export artifact history only

#### Gallery goals

- Reduce cognitive load.
- Make “start a form” and “resume a form” separate mental models.
- Keep export history out of the editable-work surface.

### 5. 1174R onboarding after shell proof

Once IDR fidelity and 1126 shell refit are stable:

- [x] register 1174R against the shared shell
- [x] define its canonical field mapping
- [x] define its section set using the same building blocks
- [ ] verify preview/export/attachment behavior on the S21 against the fresh
      shared-shell implementation

## Interface / Contract Changes

- Add a shared non-pay-app form workflow shell.
- Add a reusable section-definition contract for form editors.
- Replace 1126's bespoke top-level wizard with the shared shell.
- Update the Forms gallery IA to `Create / Saved / History`.
- Expand the canonical PDF audit contract to include 1174R.
- Make typed signature the explicit forms standard in specs/comments/tests.

## Test Plan

### PDF fidelity

- IDR:
  - field inventory preserved
  - day autofill correct
  - stable contractor/equipment row mapping
  - checkbox state correct
  - signature target correct
  - unused rows/checkboxes clear
- 1126:
  - all mapped fields exist in shipped template
  - newly exposed fields round-trip to export
  - carry-forward values export correctly
  - signature area and editable export behavior remain correct
- 1174R:
  - inventory test locked at `226` named fields
  - filler keys all exist in the shipped template
  - generated PDF writes mapped values into the shipped template
  - seeded initial row-group lengths are covered

### Workflow shell / UI

- shared shell renders section states consistently
- 1126 first-week and carry-forward flows both work inside the new shell
- signed-edit invalidation still works
- shared attach-to-entry flow still works
- preview/export remain owner-driven
- 1174 shell now has local widget coverage for:
  - shared shell sections/actions
  - project-known autofill into the response payload

### Gallery

- Create mode shows available workflows clearly
- Saved mode groups responses by form type
- History mode remains export-only
- dense mixed-list behavior is retired

### Device validation

- S21 proof for:
  - IDR export fidelity
  - 1126 fill/edit/export/attach/reopen flows
  - typed-signature path
  - daily-entry bundle export with attached 1126
  - gallery usability after mode split

## Execution Order

1. Close IDR canonical mapping fidelity.
2. Close 1126 template audit + missing capture surface.
3. Extract the shared form workflow shell.
4. Refit 1126 onto that shell.
5. Redesign the Forms gallery into `Create / Saved / History`.
6. Land 1174R onto the shared shell with canonical filler, schema, and tests.
7. Re-run targeted tests and S21 end-to-end verification.

## Next Session Restart Checklist

1. Reconnect the S21 and confirm `adb devices -l` shows the device again.
2. Reinstall the latest driver build before any new validation work.
3. Resume phone-only proof in this order:
   - weekly SESC reminder `resume draft`
   - MDOT 1174R fill/edit/preview/export/attach
   - broader 1126 / SESC workflow polish validation
4. Revisit standalone-form dated-folder/export-destination UX once device proof
   is unblocked.

## Assumptions

- Shared shell is the default, not a prison; unusually complex forms can keep
  specialized internals if they still use the shared
  shell/action/signature/attachment contracts.
- 0582B is the interaction reference, not the literal implementation template.
- Typed signatures are the only supported form-signature mode unless a future
  legal requirement forces a new contract.
- Pay apps stay outside attach-to-entry, but remain part of the broader export
  architecture.
- The record-drawings checkbox on IDR is deliberately out of scope and left
  unused/off.
