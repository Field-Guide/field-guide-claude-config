# Session State

**Last Updated**: 2026-04-13
**Branch**: `sync-engine-refactor`
**Status**: The active lane is pay-app export / analytics / tablet UI closeout using `.codex/plans/2026-04-13-pay-app-export-tablet-analytics-spec.md` as the working spec. The highest-value pay-app XLSX copy path is now live-proven on S21 `RFCNC0Y975L`: from `/quantities`, selecting saved Pay Application #5's export-copy action opened Android DocumentsUI, saved visible workbook copies in Downloads, produced a repeat copy with Android's `(1)` suffix, and Microsoft Excel opened the second copy with the `Quantities` sheet. `flutter analyze` and targeted quantities/pay-app export tests passed after the export feedback cleanup. Commit `f2133ea248d10bb6824c9403ef40b5f2d19ae494` was pushed to `origin/sync-engine-refactor`, PR #290 merged into `main` at `d97066540c53d9ca97c0030aacf7fb7e21b9916f`, and CodeMagic workflow `ios-testflight` build `69dc8febbe1c98fae68a2cc7` passed with signed IPA artifact `construction_inspector.ipa`.

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
- Google Cloud Vision OCR prerelease status:
  - remote `google-cloud-vision-ocr` Edge Function is active
  - direct Flutter/client code is lint-blocked from owning Vision calls
  - company OCR mode is server-guarded by `company_app_config`
  - full Google OCR readiness now passes
- Pay-app export / analytics / tablet UI status:
  - `.codex/plans/2026-04-13-pay-app-export-tablet-analytics-spec.md` is the current working spec
  - saved pay apps are selectable from the pay-app export UI
  - saved pay-app XLSX copies export through Android DocumentsUI instead of the in-app summary screen
  - S21 proof pulled `/sdcard/Download/pay_app_5_2026-04-12_2026-04-18 (1).xlsx` and verified it as a valid XLSX containing `Springfield DWSRF`, `Mobilization`, `Pre-Construction`, `Video Survey`, and the `Quantities` sheet
  - Microsoft Excel opened the second visible S21 copy and showed document title `pay_app_5_2026-04-12_2026-04-18 (1)` with `Quantities` selected

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

1. Use CodeMagic build `69dc8febbe1c98fae68a2cc7` artifact `construction_inspector.ipa` for iPad testing.
2. Continue the remaining UI polish from `.codex/plans/2026-04-13-pay-app-export-tablet-analytics-spec.md`, especially analytics pay-app/item drilldown visual polish after the iPad build gate is underway.
3. Keep Google OCR admin/company opt-in only; do not put the Google key in Flutter env/client code and do not reintroduce `codex-admin-sql`.

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

### Session 755 (2026-04-12, Codex)
**Work**: Implemented and live-proved Google Cloud Vision OCR via the Supabase Edge Function: added server-side company opt-in/auth checks, sanitized provider errors, tightened the direct-Google lint rule, added Edge Function contract tests, set the Supabase Google key secret, applied the missing remote OCR config table/RPC SQL, fixed Google billing/key restrictions, deployed the function, and deleted the remote `codex-admin-sql` debug function.
**Decisions**: Cloud OCR remains admin/company opt-in and defaults through `auto`; Google credentials stay server-side in Supabase secrets; Flutter code may only use the approved OCR adapter; direct Google and Edge Function smoke tests are valid setup proof, while corpus extraction quality still requires the standard PDF hardening harness.
**Next**: Resume prerelease work at PDF corpus hardening: run the new PDFs one at a time through the existing app/harness path, compare against Springfield baseline/goldens, and only make general algorithmic extraction changes.

### Session 756 (2026-04-13, Codex)
**Work**: Implemented the pay-app export UI path for selecting saved pay applications and exporting XLSX copies without prompting for a new pay-app number; added recovered workbook rebuilding when a saved pay app lacks a linked artifact; changed Android/iOS save-copy behavior to use `FilePicker.saveFile` with bytes so DocumentsUI writes a visible workbook; cleaned saved-copy success/error wording. Live-verified on S21 through Flutter run: saved Pay App #5 exported to Downloads, a second export produced `pay_app_5_2026-04-12_2026-04-18 (1).xlsx`, the pulled file was a valid XLSX with expected Springfield/pay-item strings, and Microsoft Excel opened the second copy on-device with `Quantities` selected. Targeted quantities/pay-app export tests and `flutter analyze` passed.
**Decisions**: The high-value export artifact is the visible Excel workbook, not the in-app pay-app detail/summary screen. Saved pay-app copy export should preserve the source pay-app row and produce a user-visible XLSX copy. If a historical pay app has no linked artifact, rebuilding the workbook from saved snapshots through that pay app number is acceptable as a recovery path.
**Next**: Use CodeMagic build `69dc8febbe1c98fae68a2cc7` / `construction_inspector.ipa` for iPad testing, then resume the remaining analytics/tablet polish from the pay-app export spec.
