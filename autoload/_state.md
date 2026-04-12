# Session State

**Last Updated**: 2026-04-10
**Branch**: `sync-engine-refactor`
**Status**: `sync-engine-refactor` still carries the completed sync release-proof sweep, but the active lane in this workspace is now the controlling form-fidelity/device-validation spec in `.codex/plans/2026-04-10-form-fidelity-device-validation-spec.md`: real-auth-only Samsung verification, read-only preview separation, 0582B standards relocation into Proctor with the corrected two-box chart contract, and a required two-pass live verification cycle across 0582B, 1174R, 1126, and IDR. The filled reference/export artifact bundle now exists under `.codex/artifacts/2026-04-10/pdf_fidelity_verification/`, the current 0582B export externally proves saved raw `/V` values for `B/C/D/E/F/G/H`, the production writer now writes AcroForm text values directly to `/V` so loaded read-only fields are not skipped by Syncfusion's public setter, and ad-hoc appearance-key comparison shows zero `/DA` `/Q` `/Ff` `/FT` `/AP` `/MK` drift between the generated PDFs and the shipped/original baselines for the audited forms. Latest Samsung replay proves the patched build reaches the live 0582B draft and launches preview from the saved-form path, but the specific saved draft on-device did not contain a clean proctor/test data set and raw `adb` standards entry automation was not reliable enough to count as final live proof.

## Current State

- PR `#249` merged the UI design-system refactor, including the 300-line presentation ceiling enforced by `scripts/audit_ui_file_sizes.ps1`.
- Sync-driving UI now has explicit contracts through:
  - `lib/core/driver/screen_registry.dart`
  - `lib/core/driver/screen_contract_registry.dart`
  - `lib/core/driver/flow_registry.dart`
  - `lib/core/driver/driver_diagnostics_handler.dart`
- `/diagnostics/screen_contract` is the unified sync-facing UI inspection endpoint.
- Screen-local controller composition now lives in `di/*screen_providers.dart` files across auth, entries, forms, projects, quantities, settings, dashboard, pay applications, and similar refactored features.
- CI now enforces sync adapter drift with `scripts/validate_sync_adapter_registry.py` against `sync_engine_tables.dart`, `simple_adapters.dart`, and `sync_registry.dart`.
- The legacy `BaseRemoteDatasource` sync bypass has been removed; the remaining sync work is proof breadth, not major leftover executor cleanup.
- Foreground private-channel hints are now live-proven through the owned split:
  - `RealtimeHintHandler` owns subscribe / refresh / consume
  - `SyncHintRemoteEmitter` owns push-side `emit_sync_hint(...)`
  - `sync_hint_subscriptions` is the active-channel source of truth
- New custom lint now explicitly guards:
  - `push_handler_requires_sync_hint_emitter`
  - `no_sync_hint_rpc_outside_approved_owners`
  - `no_sync_hint_broadcast_subscription_outside_realtime_handler`
  - `no_client_sync_hint_broadcast_http`
- Current live proof checkpoint is `complete` after closing:
  - delete / restore / hard-delete / revocation
  - remove-from-device / fresh-pull parity
  - file-backed create/delete/cleanup
  - integrity / maintenance
  - support-ticket and consent live flows
  - retry/restart chaos matrix
  - quick-resume and realtime-hint mode proof
  - global full sync
  - dirty-scope isolation
  - private channel register/teardown
  - final mixed-flow soak

## Quality Gates

- `flutter analyze` must stay clean.
- `dart run custom_lint` must stay clean.
- `scripts/audit_ui_file_sizes.ps1` must stay green.
- `python scripts/validate_sync_adapter_registry.py` must stay green.
- No ignore comments, analyzer excludes, or severity downgrades are permitted to bypass the lint gates.

## New Architecture Enforcement

Custom lint now explicitly enforces:
- `max_ui_callable_length`
- `max_ui_file_length`
- `screen_registry_contract_sync`

Existing rules still enforce:
- single composition roots
- no business logic in DI
- no datasource imports in presentation
- design-system widget/token usage

Cross-file sync drift is now guarded in CI by:
- `scripts/validate_sync_adapter_registry.py`

## Resume Priorities

1. Keep real-auth-only device verification as the contract. Do not validate auth or sync on mock-auth builds again.
2. Continue the reopened Samsung live-device verification on the corrected real-auth build, including the bad-sync/background-resume cycle that still needs a fresh replay.
3. Use the original debug/source PDFs as the fidelity baseline and do not close the form lane until preview/export typography, alignment, and auto-filled fields match the source AcroForms closely enough to satisfy the live reference check.

### Session 747 (2026-04-07, Codex)
**Work**: Merged the UI design-system refactor, closed the last UI issues, added structural sync adapter drift validation, and switched the workspace back to `sync-engine-refactor`.
**Decisions**: Treat GitHub issues as the defect system of record; do not use `.claude/defects`. Enforce sync adapter drift with a structural validator instead of count-based CI checks.
**Next**: Catch `sync-engine-refactor` up to the merged UI baseline, then continue the sync delete-orchestration split against the new UI orchestrator/provider/controller endpoints.

### Session 748 (2026-04-07, Codex)
**Work**: Locked in the broad sync ownership lints, added a pull-only local-write guard, repaired upgraded-install sync drift, and ran `custom_lint` to expose the remaining legacy Supabase sync access layer instead of hiding it.
**Decisions**: Keep `no_raw_supabase_sync_table_io_outside_supabase_sync` broad even if it surfaces many violations; treat the exposed remote datasource and shared datasource usage as real Phase 0 architecture debt before final release proof.
**Next**: Burn down the broad lint backlog starting with legacy remote datasources and `BaseRemoteDatasource`, then resume live proof at remove-from-device/fresh-pull parity using the phased plan.

### Session 749 (2026-04-07, Claude Opus 4.6)
**Work**: Implemented the full MDOT 1126 Weekly SESC Report plan via the implement skill (10 phases) using Agent-tool dispatch (no headless), with code-review + completeness reviewers only (no security per user request). Added signature_files / signature_audit_log SQLite v54 + Postgres migration, signatures feature module, sync adapters, 7 forms domain use cases, MDOT 1126 validator + PDF filler + registrations, full wizard presentation layer (controller, header step, rainfall, tri-state measures, drawn signature pad, attach), export-bundling block-on-unsigned, weekly reminder UI bindings, and Phase 10 sync registry + lint allowlist integration. Caught and fixed: HIGH SECURITY DEFINER search_path injection in Postgres trigger functions; CRITICAL WizardActivityTracker DI lookup that would have crashed every wizard launch; HIGH infinite refresh loop in SescReminderProvider (resolved/pending sets); two plan gaps (missing header step, missing GPS capture per SEC-1126-08) per user option C. Working tree on `sync-engine-refactor` was broken into 13 logical commits by layer (sync refactor / sync lint rules / project assignments / 10 MDOT 1126 phase commits) and pushed.
**Decisions**: Headless mode is too slow/lossy — use Agent tool for all dispatches per global feedback. Run review/fix sweeps from main conversation, not inside the orchestrator. Always verify agent "done" claims with direct grep before accepting. Mixed-DI files (app_dependencies.dart, app_providers.dart, sync_registry.dart, sync_engine_tables.dart, simple_adapters.dart, project_lifecycle_integration_test.dart) are committed in their MDOT 1126 phase commit with the message acknowledging they bundle concurrent-session refactor work — splitting hunks across commits would have required interactive `git add -p`. Header lives only in `FormResponse.headerData` (canonical 0582B pattern); date helpers consolidated in `lib/shared/utils/date_format.dart`. AppVersion sourced from `AppConfigProvider` with a drift test instead of hardcoding pubspec strings.
**Next**: Manual driver verification of the 1126 wizard end-to-end (first-week + carry-forward), weekly reminder visibility on dashboard/entry/toolbox, edit-after-sign export blocking, and daily export bundle (IDR + 1126 PDF + photos in one folder). Run `npx supabase db push` to land `20260408000000_signature_tables.sql` before any device test. Follow-ups documented in checkpoint: back-fill spec §2 audit table to mention `signature_png_sha256`, abstract `dart:io` out of `sign_form_response_use_case.dart` via a `SignatureFileStore` port, address pre-existing `lib/features/entries/data/datasources/remote/remote_datasources.dart` dangling export error, clean stale flusseract Windows ephemeral build cache so `dart run custom_lint` can run locally again. Phase 10 sync_registry/sync_engine_tables changes should also be smoke-tested for the auto-trigger generation path the implementer noted as a future hardening target.

### Session 750 (2026-04-07, Codex)
**Work**: Closed the foreground private-channel hint lane live, then locked the contract into docs and lint rules. Added `SyncHintRemoteEmitter` as the explicit push-side owner of `emit_sync_hint(...)`, simplified active-channel lookup to `sync_hint_subscriptions`, updated the `.claude` sync docs/state to match the shipped architecture, and added four sync-hint lint rules to stop future ownership drift.
**Decisions**: Foreground invalidation is now an owned contract, not a trigger side effect. `RealtimeHintHandler` is the only normal client subscriber, `SyncHintRemoteEmitter` is the only normal client emitter, and raw client `/realtime/v1/api/broadcast` use is forbidden.
**Next**: Resume live proof at `global-full-sync-proof`, followed by dirty-scope isolation, private channel register/teardown, and the final mixed-flow soak.

### Session 751 (2026-04-07, Codex)
**Work**: Completed the remaining live validation lanes on Windows + S21, including global full sync, dirty-scope isolation, private channel teardown/rebind, and the final mixed-flow soak. Fixed the last scoped-hint parsing gap by normalizing nested private-broadcast envelopes in `RealtimeHintHandler`, then proved the final release matrix end to end.
**Decisions**: The release-proof sweep is complete. Full sync remains the no-hint catch-up path, quick sync now respects strict dirty scopes from private broadcasts, `sync_hint_subscriptions` is confirmed as the private-channel lifecycle source of truth, and the broad sync lints stay in place with no narrowing.
**Next**: Close out artifacts, review any optional non-blocking harness cleanup, and keep future sync changes behind the existing ownership and hint-contract lint gates.

### Session 752 (2026-04-10, Codex)
**Work**: Closed the 0582B preview/export fidelity issues, added density/moisture standards entry in the hub flow, restored form-field alignment/pan-zoom/navigation behavior, and captured Samsung sync recovery screenshots. A later Samsung settings screenshot proved the installed build was still using mock auth (`Test User` / `test@example.com`), so runtime mock-auth support was removed from config/router/auth provider paths, the explicit `MOCK_AUTH` ban was added to `.codex/AGENTS.md`, and the old mock-autologin test file was deleted. `flutter clean` and `flutter pub get` completed, but the fresh debug APK rebuild was interrupted after the editor/session slowdown.
**Decisions**: Do not validate auth or sync on mock-auth builds again. Prefer real sessions, real backend state, and stale-state cleanup guards over runtime auth bypasses. Treat `.codex/plans/2026-04-10-0582b-preview-sync-recovery-plan.md` as the primary crash-safe handoff for this lane.
**Next**: Rebuild the debug APK after the notes are saved, uninstall the stale Samsung app, install the fresh APK, capture a new device screenshot proving real-auth state, and continue live sync verification only on the real backend path.

### Session 753 (2026-04-10, Codex)
**Work**: Restarted the local build/device layer, rebuilt and reinstalled a fresh real-auth debug APK, proved the Samsung now opens on the real login screen instead of the old mock-auth session, signed in with the real inspector account, passed consent, and confirmed sync health on-device. That live replay exposed a post-auth routing bug: after consent the app landed on `Dashboard` with `No Project Selected`. Fixed the route owners so fresh auth/consent and no-project dashboard taps land on `Projects` instead. Also audited the handoff notes with two agent passes, reopened the still-live device items, and identified a separate inspector-role contract bug in the Calendar no-project state: it still shows `Create Project`.
**Decisions**: Treat code/test green and live-device green as separate states in the notes. Keep the reopened TODO list explicit until the real-device Samsung replay and the project-backed 0582B lane are both complete.
**Next**: Fix the inspector Calendar no-project CTA so inspectors never see `Create Project`, then continue Samsung live-device validation. After that, resume 0582B device verification only when a real project exists for the inspector account.

### Session 754 (2026-04-10, Codex)
**Work**: Fixed the inspector Calendar no-project CTA so inspector empty states route to `View Projects` instead of exposing `Create Project`, restarted the local Android/ADB/driver layer from a clean state, re-ran the Samsung bad-sync/background-resume recovery on the corrected real-auth build, inserted and assigned a real MDOT project through the live backend, and resumed the real on-device 0582B flow through project selection, form creation, and PDF preview. The live preview proved the 0582B path is no longer blank, but the user then raised a stricter remaining defect: preview/export formatting still drifts from the original PDF font/field behavior and 0582B columns F/G/H still do not match the original form's auto-fill contract.
**Decisions**: The form lane is not closed by "preview not blank." The closeout gate is now the original/source PDFs themselves. Verification must compare against the original AcroForms, fill every field in the reference forms, preserve original appearance as closely as possible, and save durable filled-reference artifacts for 0582B, 1174R, 1126, and IDR.
**Next**: Inspect `DEBUG_mdot_0582b_density.pdf` and `DEBUG_mdot_1174r_concrete.pdf` directly, enumerate field/appearance expectations, repair the remaining font/alignment/F-G-H fidelity gaps, generate/save the four fully filled verification PDFs, and then finish targeted tests plus final on-device validation.
