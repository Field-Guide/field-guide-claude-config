# CodeMunch Beta Audit Reference

Date: 2026-04-08
Branch: `sync-engine-refactor`

This document is the standing reference for the current beta push. It ties the
Notion export, the CodeMunch index, and the current codebase state together so
future iterations can keep comparing implementation work against the same
source of truth.

## Source Inputs

- Notion export archive: `C:\Users\rseba\Downloads\5b90c3ca-669b-4e39-8e31-e3a780d3e92d_ExportBlock-632c1bec-067b-4009-a4c5-2c573dd8c5e1.zip`
- Extracted Notion markdown: `%TEMP%\notion_beta_export_632c1bec\inner\Field_Guide_App_Notion_Import_2026-04-07 33cc3411c1b58029a802cc3289f9cbab.md`
- CodeMunch repo index: `local/Field_Guide_App-37debbe5`
- CodeMunch index time: `2026-04-08T08:37:15.166724`
- CodeMunch symbol count: `13936`

## Beta State

The following beta slices are now validated and should stay green while the
remaining architecture cleanup continues:

- Production routing and driver routing parity
- Auth redirect proof
- Shipped forms export proof for IDR, MDOT 0582B, and MDOT 1126
- Pay-app export and detail flows
- Sync-hint RPC ownership and state-refresh lint cleanup
- `flutter analyze`
- `dart run custom_lint`

## God-Sized Surfaces To Keep Tracking

These are the highest-risk surfaces surfaced by the CodeMunch size scan and
should stay on the active decomposition radar:

- `lib/core/database/database_service.dart`
- `lib/core/driver/driver_server.dart`
- `lib/features/forms/data/services/form_pdf_service.dart`
- `lib/features/pdf/services/extraction/pipeline/extraction_pipeline.dart`
- `lib/features/pdf/services/pdf_service.dart`
- `lib/features/sync/engine/integrity_checker.dart`
- `lib/features/sync/engine/local_sync_store.dart`
- `lib/features/projects/data/services/project_lifecycle_service.dart`
- `lib/features/pdf/services/extraction/shared/post_process_utils.dart`
- `lib/features/pdf/services/extraction/ocr/tesseract_engine_v2.dart`
- `lib/features/pay_applications/data/services/pay_app_import_parser.dart`
- `lib/features/entries/presentation/controllers/entry_editing_controller.dart`
- `lib/features/projects/presentation/controllers/project_setup_controller.dart`
- `lib/features/forms/presentation/controllers/form_viewer_controller.dart`
- `lib/features/pay_applications/presentation/screens/pay_application_detail_screen.dart`

## Current Beta Work Queue

The remaining beta work should be pulled from the unified todo, but the
priority order is now:

1. Decompose the largest remaining service/controller surfaces into explicit
   endpoints and keep the lint coverage enforcing that shape.
2. Continue the dead-code sweep and remove stale helpers or abandoned
   scaffolding created during the refactor waves.
3. Keep the forms/pay-app/sync proof slices green while the structural cleanup
   lands.
4. Keep routing standardized on named routes and the production shell/forms
   contracts.

## Reference Notes

- Do not reintroduce RPC wrappers in non-owner layers.
- Do not weaken the custom lint rules to accommodate legacy patterns.
- Treat this artifact as the current comparison point when updating the beta
  todo or deciding whether a new surface belongs in the release gate.

## 2026-04-08 19:34 ET Addendum: Sync Recovery And UI Contract Direction

### Standing Diagnosis

The current beta risk is no longer just oversized files. The active systemic
risk is stale local sync state surviving source fixes and continuing to distort
user-facing behavior. The repo needs a repair architecture, not just more
retry logic.

### CodeMunch-Backed Direction

- Repair seam:
  - run versioned sync repair jobs from `lib/features/sync/application/sync_initializer.dart`
  - persist applied job markers in `sync_metadata` via `lib/features/sync/engine/sync_metadata_store.dart`
- Keep derived diagnostics non-authoritative:
  - `conflict_log`
  - integrity metadata
  - dashboard counters
- Treat truth as:
  - real local rows
  - pending queue state
  - applied repair metadata

### First Enforcement Targets

- Add `SyncStateRepairRunner` and versioned repair jobs.
- Add lint coverage for entry-flow route intents.
- Add lint coverage that keeps integrity diagnostics out of user-facing sync presentation.
- Add lint coverage for raw/unconstrained scrollable bottom-sheet content.

### Known Code Smells To Keep Visible

- `lib/core/design_system/surfaces/app_bottom_sheet.dart`
  - current `Flexible(child: builder(...))` pattern is too permissive and invites exactly the sheet sizing/scroll affordance bugs reported during beta
- `lib/features/forms/presentation/screens/form_gallery_screen.dart`
  - raw `ListView` returned from `AppBottomSheet.show` builder is a likely direct contributor to the broken Forms sheet behavior
- Entry flow route ownership is still fragmented across dashboard and entries presentation surfaces instead of passing through one intent layer
- Sync integrity data still exists on the user-facing controller/query path even though the section is no longer intended to be user-facing

### Guardrail Principle

If a bug can poison local sync state, the fix is incomplete until all three are
present:
- code fix
- repair for already-bad local state
- dirty-upgrade regression test
