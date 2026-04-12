# 2026-04-10 0582B Preview + Sync Recovery Plan

## Scope

Controlling spec reference:

- `.codex/plans/2026-04-10-form-fidelity-device-validation-spec.md`
  - This is now the authoritative closure contract for implementation order,
    per-form fidelity gates, post-verification review, and final all-forms
    re-verification on the real-auth Samsung build.

User-reported beta issues to close in one coordinated pass:

- [x] 0582B preview shows blank output after header/proctor/test entry
- [x] 0582B lacks density/moisture standards entry in the live hub flow
- [x] 0582B exports are injecting unintended data into remarks
- [x] 0582B F/G/H proctor columns are not autofilling as expected
- [x] exported form field appearance drifts from the canonical AcroForm alignment
- [x] PDF preview needs pan + zoom instead of static `PdfPreview`
- [x] non-shell form/preview routes need a reliable escape/navigation affordance
- [x] Samsung bad-sync/background recovery needs reproduction, patch, and screenshot proof

## Closure Standard

An item is only closed when all of the following are true:

- [x] source path is fixed
- [x] targeted tests cover the contract where feasible
- [x] `flutter analyze` is clean for touched files
- [x] relevant targeted `flutter test` slices are green
- [x] Samsung device proof is captured for the sync/resume issue

## Working Notes

- Current likely owners:
  - `mdot_hub_controller*`, `hub_*` widgets, `mdot_0582b_pdf_filler.dart`
  - `form_pdf_field_writer.dart`, `form_pdf_rendering_service.dart`
  - `form_pdf_preview_screen.dart`, `entry_pdf_preview_screen.dart`
  - `scaffold_with_nav_bar.dart`, affected non-shell form screens
  - `sync_lifecycle_manager.dart`, `shell_banners.dart`, `sync_provider.dart`
- 2026-04-10 code/test closeout:
  - [x] 0582B preview shows blank output after header/proctor/test entry
  - [x] 0582B lacks density/moisture standards entry in the live hub flow
  - [x] 0582B exports are injecting unintended data into remarks
  - [x] 0582B F/G/H proctor columns are not autofilling as expected
  - [x] exported form field appearance drifts from the canonical AcroForm alignment
  - [x] PDF preview needs pan + zoom instead of static `PdfPreview`
  - [x] non-shell form/preview routes need a reliable escape/navigation affordance
  - [x] Samsung bad-sync/background recovery needs reproduction, patch, and screenshot proof
  - [x] source path is fixed
  - [x] targeted tests cover the contract where feasible
  - [x] `flutter analyze` is clean for touched files
  - [x] relevant targeted `flutter test` slices are green
  - [x] Samsung device proof is captured for the sync/resume issue
  - [ ] full-repo `flutter analyze` is globally green
  - [ ] full live-device 0582B validation is complete
  - Note: full-repo analyze still reports pre-existing unrelated issues in `third_party/custom_lint_patched`, `third_party/printing_patched`, `lib/features/sync/presentation/support/conflict_presentation_mapper.dart`, and dirty auth test files that were out of scope for this pass.
  - Note: this block is code/test closeout only. Live-device validation is still partial and is tracked in the reopened TODOs below.

## Crash-Safe Resume Checkpoint

- Samsung screenshot proof later showed the installed device build was still on mock auth:
  - `.codex/artifacts/2026-04-10/samsung_pre_auth_check.png`
  - Settings showed `Test User` / `test@example.com`, so earlier "real-auth build" verification was invalid.
- User direction changed after that proof:
  - remove runtime mock auth instead of preserving it
  - do not validate auth/sync on mock-auth builds again
  - prefer stale-state exposure plus real cleanup guards over artificial auth bypasses
- Runtime mock-auth removal has been applied in code:
  - `.codex/AGENTS.md` now explicitly says `Do not use MOCK_AUTH; verify auth and sync only against real sessions and real backend state.`
  - removed `MOCK_AUTH`/autologin runtime branches from `lib/core/config/test_mode_config.dart`
  - removed the router bypass from `lib/core/router/app_redirect.dart`
  - removed mock-auth runtime wiring from `lib/features/auth/presentation/providers/auth_provider.dart`
  - removed mock-auth branches from auth action/recovery partials
  - deleted `lib/features/auth/presentation/providers/auth_provider_mock_actions.dart`
  - deleted `test/features/auth/presentation/providers/auth_provider_mock_autologin_test.dart`
- Auth/runtime verification already completed after those edits:
  - targeted `flutter analyze` on touched auth/router/config files: green
  - `flutter test test/core/router/app_redirect_test.dart`: green
  - `flutter test test/features/auth/presentation/providers/auth_provider_test.dart`: green
- Build/reinstall checkpoint before this session crash:
  - `flutter clean`: completed
  - `flutter pub get`: completed
  - `flutter build apk --debug --dart-define-from-file=.env`: started, then became the likely source of the VS Code slowdown/crash and was interrupted before completion
- Historical next resume step:
  - avoid broad rebuild/analyze work until notes are saved
  - finish a fresh debug APK build only after handoff notes are current
  - uninstall stale Samsung app data, install the fresh APK, capture a new screenshot, and verify real sign-in/sync only against the live backend
- 2026-04-10 real-build reset checkpoint:
  - killed stale `adb`, Dart, Gradle, Kotlin, and Java language-server processes, then restarted only the device/build path
  - `.\android\gradlew.bat --stop`: no Gradle daemons running after reset
  - `adb kill-server` / `adb start-server`: cycled cleanly
  - `adb -s RFCNC0Y975L uninstall com.fieldguideapp.inspector`: success
  - `flutter build apk --debug --dart-define-from-file=.env --target-platform android-arm64`: success
  - `adb -s RFCNC0Y975L install -r build\app\outputs\flutter-apk\app-debug.apk`: success
  - fresh screenshot proof after reinstall:
    - `.codex/artifacts/2026-04-10/samsung_post_real_build.png`
    - device now opens to the real login screen (`Field Guide`, `Sign in to continue`) instead of the old mock-auth settings page
- 2026-04-10 post-auth landing correction:
  - real inspector login and consent initially reproduced a routing bug: the app landed on `Dashboard` with `No Project Selected`
  - root cause:
    - auth/onboarding screens were hard-coding `goNamed('dashboard')`
    - router fallback/default location still preferred `/`
    - dashboard nav tab still routed to `/` even when no project was selected
  - patched route owners:
    - `lib/core/router/app_router.dart`
    - `lib/core/router/app_redirect.dart`
    - `lib/core/router/scaffold_with_nav_bar.dart`
    - `lib/features/auth/presentation/screens/login_screen.dart`
    - `lib/features/auth/presentation/screens/company_setup_screen.dart`
    - `lib/features/auth/presentation/screens/pending_approval_screen.dart`
    - `lib/features/settings/presentation/screens/consent_screen.dart`
  - verification:
    - `flutter analyze` on the touched router/auth files and router tests: green
    - `flutter test test/core/router/app_redirect_test.dart test/core/router/app_router_test.dart test/core/router/scaffold_with_nav_bar_test.dart`: green
    - fresh Samsung replay after reinstall now lands on `Projects` after real login + consent:
      - `.codex/artifacts/2026-04-10/samsung_post_consent_fixed_2.png`
  - current live-data limitation:
    - the real inspector account is healthy and synced, but `Projects` currently shows no device projects and no company projects, so deeper on-device 0582B workflow verification remains blocked on backend project availability rather than on auth/routing/sync state

## Open / Reopened TODOs

- [x] Re-open the PDF fidelity lane against the original AcroForms, not just the app-rendered preview
  - new verification gate from the user:
    - open the original debug/source PDFs directly and use them as the formatting baseline
    - fill every text box / AcroForm field in the reference forms
    - verify both preview output and exported output preserve the original form formatting instead of flattening into left-aligned substitute text
  - required forms in this gate:
    - 0582B
    - 1174R
    - SESC 1126
    - Daily Entries / IDR
  - required artifacts:
    - save fully filled verification PDFs for all four forms in a durable artifact location
    - keep the originals and the generated verification copies paired for later regression checks
  - current artifact location:
    - `.codex/artifacts/2026-04-10/pdf_fidelity_verification/`
    - includes `source/`, `reference_filled/`, `generated/`, and the manifest for the required gate

- [x] Inspect the provided original PDFs and lock the exact field/appearance contract before more form changes
  - user-provided source files:
    - `C:\Users\rseba\OneDrive\Desktop\DEBUG_mdot_1174r_concrete.pdf`
    - `C:\Users\rseba\OneDrive\Desktop\DEBUG_mdot_0582b_density.pdf`
  - required follow-up:
    - enumerate AcroForm field names/types/default appearance where possible
    - compare font/alignment/justification behavior against the app-filled output
    - record which fields are expected to auto-calculate inside the source form versus being precomputed by our filler
  - current evidence:
    - `.codex/artifacts/2026-04-10/pdf_fidelity_verification/field_contract_comparison.json`
    - current comparison shows `0582b_original_vs_shipped` and `1174r_original_vs_shipped` with zero field-contract differences for the compared field metadata

- [x] Re-verify and likely repair 0582B F/G/H autofill against the original density form
  - user-provided input check:
    - column B moisture = `8`
    - column C = `.0439`
    - column D = `4600`
    - column E = `2006`
  - required result:
    - columns F/G/H must auto-fill exactly like the original PDF does
    - verify in both preview and exported output, not only in filler unit tests
  - current blocker:
    - earlier stale artifact inspection suggested blank `/V` values, but the current regenerated artifact now externally confirms:
      - `BRow1=8`
      - `CRow1=.0439`
      - `DRow1=4600`
      - `ERow1=2006`
      - `FRow1=2594`
      - `GRow1=5.72`
      - `HRow1=130.2`
    - the active remaining gate is visual/original-form fidelity across preview/export, not missing raw field values for the current 0582B artifact

- [x] Re-verify and likely repair font/appearance preservation across all form exports
  - earlier preview work proved the form is no longer blank, but the user reports the text styling still differs from the original form
  - required follow-up:
    - preserve the original AcroForm field appearance as closely as the source document allows
    - confirm entered text is not left-edge anchored where the original field renders centered
    - confirm the fix applies to preview and exported PDFs for 0582B, 1174R, 1126, and IDR
  - explicit artifact gate:
    - keep the original/source PDFs, fully filled debug references, and generated business-value exports together under `.codex/artifacts/2026-04-10/pdf_fidelity_verification/`
    - do not close this item until rendered-page evidence and raw field-value inspection both agree with the expected output
  - current proof:
    - targeted regression now checks raw saved `/V` values for 0582B `FRow1/GRow1/HRow1`, not only `field.text`
    - `form_pdf_field_writer.dart` now writes text fields through the AcroForm `/V` dictionary directly instead of relying on Syncfusion's public `PdfTextBoxField.text` setter, which skips loaded read-only fields
    - focused regression `test/features/forms/services/form_pdf_field_writer_test.dart` proves read-only 0582B calculated fields keep their read-only contract while persisting saved `/V` values
    - ad-hoc appearance-key comparison against the artifact bundle shows zero differences for `/DA`, `/Q`, `/Ff`, `/FT`, `/AP`, and `/MK` between:
      - shipped vs generated: 0582B, 1174R, 1126, IDR
      - original vs generated: 0582B, 1174R
    - alignment-preservation tests remain green for 0582B, 1174R, 1126, and IDR against the shipped templates
    - field-contract comparison currently shows:
      - `0582b_shipped_vs_generated`: zero compared field-contract differences
      - `1174r_shipped_vs_generated`: zero compared field-contract differences
      - `idr_shipped_vs_generated`: zero compared field-contract differences
      - `1126_shipped_vs_generated`: only a false-positive `/Rect` object-reference representation on `REMARKSRow1`; dereferenced coordinates match

- [x] Inspector calendar no-project state must not expose `Create Project`
  - current behavior: the Calendar tab no-project empty state still shows `Create Project` and routes toward project creation even for inspector accounts
  - code owner:
    - `lib/features/entries/presentation/widgets/home_no_projects_state.dart`
  - permission source of truth already exists:
    - `lib/features/auth/presentation/providers/auth_provider.dart` (`canCreateProject`)
  - audit context:
    - `.codex/plans/2026-04-08-beta-central-tracker.md:560` already states inspector project-creation flows are not part of the verification surface, so the current UI is out of contract
  - required follow-up:
    - gate the CTA by role/permission
    - add widget coverage for inspector vs manager/admin no-project states
  - current verification:
    - `flutter analyze lib\features\entries\presentation\widgets\home_no_projects_state.dart test\features\entries\presentation\widgets\home_no_projects_state_test.dart`: green
    - `flutter test test\features\entries\presentation\widgets\home_no_projects_state_test.dart`: green (`+3`)
    - final real-auth Samsung proof:
      - backed up `FlutterSharedPreferences.xml`, removed only the local
        per-user `last_project` preference, force-stopped/relaunched, opened
        Calendar, then restored the original preference file
      - `.codex/artifacts/2026-04-10/device_validation/181_calendar_no_project_inspector_after_pref_clear.png`
      - `.codex/artifacts/2026-04-10/device_validation/181_calendar_no_project_inspector_after_pref_clear.xml`
      - UI XML showed `Select a Project` and `View Projects`, with
        `Create Project` count `0`
      - restore proof:
        `.codex/artifacts/2026-04-10/device_validation/182_after_restore_project_pref.xml`

- [x] Re-run the Samsung bad-sync/background-resume failure cycle on the corrected real-auth build
  - the active plan still carries the earlier Samsung recovery lane as closed, but the later auth audit proved part of the prior device verification was invalid because the stale device was still on mock auth
  - current real-auth replay has verified:
    - clean login
    - consent
    - sync health
    - correct post-auth landing to `Projects`
  - still missing on the corrected build:
    - a deliberate bad-sync/background-resume repro and recovery proof
  - 2026-04-10 final APK re-verification:
    - evidence:
      - `.codex/artifacts/2026-04-10/device_validation/179_background_sync_resume_after_review_fix.png`
      - `.codex/artifacts/2026-04-10/device_validation/179_background_sync_resume_after_review_fix.xml`
      - `.codex/artifacts/2026-04-10/device_validation/179_background_sync_resume_after_review_fix_log_excerpt.txt`
    - device was backgrounded for more than the 30-second sync debounce window
    - background quick sync initially hit a real DNS reachability failure:
      `Failed host lookup` and `DNS unreachable before attempt 1/3`
    - the same real-auth session recovered on retry after resume:
      `Reachability check passed (HTTP 401)`,
      `quick push complete: 0 pushed, 0 errors`,
      `quick pull complete: 0 pulled, 0 errors`, and
      `Sync cycle (quick): pushed=0 pulled=0 errors=0 conflicts=0`
    - resumed UI XML had no `Sync failed`, `sync failed`, `Connectivity`, or
      `broken` text and remained usable

- [x] Investigate slow warm resume from background on the Samsung device
  - current user report: reopening from background still takes roughly 4 seconds before the app becomes usable
  - this is separate from the incorrect post-auth landing bug and should be treated as a resume-performance defect
  - required follow-up:
    - reproduce on the corrected real-auth build
    - capture timing/screenshot evidence around foreground resume
    - determine whether the delay is shell rebuild, auth/session restoration, sync startup, or project bootstrap work
  - current reproduction on corrected real-auth build:
    - backgrounded app with Android Home, waited 3 seconds, relaunched package
      `com.fieldguideapp.inspector`
    - first poll matching app content returned after about `2782 ms`
    - evidence:
      - `.codex/artifacts/2026-04-10/device_validation/68_warm_resume_home_before.png`
      - `.codex/artifacts/2026-04-10/device_validation/68_warm_resume_after.png`
      - `.codex/artifacts/2026-04-10/device_validation/68_warm_resume_after.xml`
    - this is reproduced but not repaired; next step is timing breakdown
      between shell restore, auth/session restore, sync startup, and project
      bootstrap
  - 2026-04-10 follow-up timing breakdown on the same real-auth Samsung build:
    - from IDR PDF preview:
      - `am start -W` reported `LaunchState: HOT`, `TotalTime=57ms`,
        `WaitTime=62ms`
      - first polling loop content match was about `2448 ms`, but this includes
        repeated `uiautomator dump` overhead and is not a direct app frame time
      - log evidence:
        `.codex/artifacts/2026-04-10/device_validation/131_warm_resume_log_excerpt.txt`
      - important log finding:
        `SyncLifecycleManager: Skipping resume sync trigger`, so this repro
        did not support the theory that bad sync/auth recovery was blocking
        resume
    - from project dashboard:
      - `am start -W` reported `LaunchState: HOT`, `TotalTime=70ms`,
        `WaitTime=71ms`
      - Android/Flutter first-frame logs appeared immediately in the resume
        window; first polling-loop content match again took about `2469 ms`
        because the measurement is dominated by UI dump timing
      - log evidence:
        `.codex/artifacts/2026-04-10/device_validation/135_dashboard_resume_log_excerpt.txt`
    - current assessment:
      - auth restoration and resume sync are not the observed blocker in these
        two runs
    - if the user still sees a roughly 4 second delay by eye, the next pass
      should capture a screen recording / frame timeline rather than rely on
      `uiautomator dump` polling
  - 2026-04-10 final APK re-verification:
    - evidence:
      - `.codex/artifacts/2026-04-10/device_validation/178_warm_resume_after_review_fix.png`
      - `.codex/artifacts/2026-04-10/device_validation/178_warm_resume_after_review_fix.xml`
      - `.codex/artifacts/2026-04-10/device_validation/178_warm_resume_after_review_fix_log_excerpt.txt`
    - `am start -W` reported `LaunchState: HOT`, `TotalTime=57ms`,
      `WaitTime=61ms`
    - PowerShell-measured command wall time was `161ms`
    - app log showed `SyncLifecycleManager: Skipping resume sync trigger`, so
      the warm resume path did not block on auth/session restore or sync

- [x] Complete post-verification review and final all-form re-verification
  - first-pass live real-auth Samsung preview/export validation is complete for
    the seeded project-backed all-form dataset, but the controlling spec still
    requires an implementation review followed by one more full all-form
    end-to-end re-verification before final closeout
  - completed first-pass proof:
    - 0582B preview/export:
      `.codex/artifacts/2026-04-10/device_validation/87_0582b_preview_after_standards_fix.png`,
      `.codex/artifacts/2026-04-10/device_validation/87_0582b_preview_after_standards_fix.xml`,
      `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_seeded_after_standards_fix_device_export.pdf`
    - 1126 preview/export:
      `.codex/artifacts/2026-04-10/device_validation/92_1126_seed_preview.png`,
      `.codex/artifacts/2026-04-10/device_validation/92_1126_seed_preview.xml`,
      `.codex/artifacts/2026-04-10/device_validation/MDOT_1126_seeded_signed_device_export.pdf`
    - 1174R preview/export:
      `.codex/artifacts/2026-04-10/device_validation/112_1174r_preview.png`,
      `.codex/artifacts/2026-04-10/device_validation/112_1174r_preview.xml`,
      `.codex/artifacts/2026-04-10/device_validation/MDOT_1174R_seeded_device_export.pdf`
    - IDR preview/export:
      `.codex/artifacts/2026-04-10/device_validation/124_idr_pdf_preview.png`,
      `.codex/artifacts/2026-04-10/device_validation/124_idr_pdf_preview.xml`,
      `.codex/artifacts/2026-04-10/device_validation/idr_04-07_172657/DWR_04-07.pdf`
  - verified during first pass:
    - each preview XML had `EditText` count `0`
    - 0582B export preserved AcroForm fields and wrote row 1, not row 0
    - 0582B export wrote `B=8`, `C=.0439`, `D=4600`, `E=2006`,
      `F=2594`, `G=5.72`, `H=130.2`
    - 0582B chart standards wrote both chart boxes and operating standards
      wrote the single operating boxes
    - 1126 export used the real typed-signature flow for
      `E2E Test Inspector`, producing signature audit/file rows before export
    - 1174R and IDR exports preserved AcroForm fields and carried the seeded
      representative values
  - caveat:
    - this first pass used DB-seeded project-backed validation records to cover
      all four form surfaces on the real app/device; it did not use mock auth
      and did not use test-only runtime hooks
  - 2026-04-10 final APK update:
    - post-verification review found and repaired preview cache header hashing,
      0582B stale zero-number weights-only proctor rows, and explicit
      1126/1174R preview coverage
    - final all-form preview/export device re-verification was completed on
      fresh APK SHA256
      `CE55975FBA7084B728AEAB6EB67E38E12D144F2C05A97C6B32C152045E3C45AE`
    - consolidated final proof is recorded in
      `.codex/plans/2026-04-10-form-fidelity-device-validation-spec.md`

- [x] Continue live-device 0582B verification only after a real project is available
  - current real inspector account is healthy and synced but has:
    - no device projects
    - no company projects
  - update:
    - a real MDOT project was later inserted and assigned so the device flow is no longer blocked on project availability
    - live proof was resumed through project selection and a real 0582B draft/preview path
    - latest device replay after the direct AcroForm `/V` writer fix:
      - fresh patched APK installed on Samsung (`RFCNC0Y975L`)
      - app opened on the real `Projects` list with `Live 0582B Verification`
      - project shell opened successfully
      - `Toolbox -> Forms -> Saved -> MDOT 0582B` path is reachable on-device
      - live 0582B draft screen opened and `Preview PDF` launched successfully on-device
      - current screenshot artifacts:
        - `.codex/artifacts/2026-04-10/samsung_pdf_writer_patch_launch.png`
        - `.codex/artifacts/2026-04-10/samsung_after_project_open.png`
        - `.codex/artifacts/2026-04-10/samsung_forms_tool.png`
        - `.codex/artifacts/2026-04-10/samsung_forms_saved_exact.png`
        - `.codex/artifacts/2026-04-10/samsung_0582b_draft_screen.png`
        - `.codex/artifacts/2026-04-10/samsung_0582b_preview_after_writer_fix.png`
      - caveat:
        - the saved device draft used in this replay only had header-level data plus partial shell state, so it does not yet count as final live proof for proctor/test values or F/G/H autofill
        - raw `adb shell input text` automation proved unreliable for standards entry on the Samsung numeric keyboard and concatenated multiple intended values into one field, so that attempt is not valid verification and should not be counted as closed
  - still missing for closeout:
    - the stricter original-AcroForm fidelity verification gate
    - export-vs-original comparison artifacts for the four required forms
    - final on-device replay after the remaining PDF fidelity fixes land

- [x] Keep the 2026-04-10 plan honest about “code closed” vs “live verified”
  - code/test/router/auth landing fixes are green
  - live form/workflow proof is still partial because the environment lacks a project-backed verification surface

## 2026-04-10 Spec Addendum

- 0582B standards contract correction:
  - chart standards are not a single density/moisture pair
  - chart standards must map to two chart boxes for density and two chart
    boxes for moisture
  - operating standards remain a single density/moisture pair
- 0582B standards location correction:
  - chart and operating standards belong to the Proctor section
  - they are out of contract in Quick Test and must be removed from there
- Preview contract correction:
  - preview must be read-only across the validated forms
  - preview must use a filled flattened copy so `SfPdfViewer` cannot
    double-render AcroForm field text over the page
  - exported forms must still preserve the AcroForm contract
- 0582B numbering correction:
  - PDF-visible test/proctor row numbers are one-based; stale `0` values must
    fall back to the one-based row index instead of being written to the form
  - new 0582B responses must start with empty `test_rows`/`proctor_rows`, not
    seeded blank placeholder rows
  - existing blank seed rows must be ignored by parsed rows, PDF mapping, and
    test-number derivation so they cannot create phantom row 1 / row 0
    behavior or push real values into the next PDF row
  - 2026-04-10 verification finding:
    - pulled Samsung export
      `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_after_export_snapshot_fix_device_export.pdf`
      preserved AcroForm fields and exported B-H, but stale blank seed rows
      occupied the first proctor/test row
    - patched owners:
      - `lib/features/forms/data/registries/mdot_0582b_registrations.dart`
      - `lib/features/forms/data/models/form_response.dart`
      - `lib/features/forms/data/pdf/mdot_0582b_pdf_filler.dart`
      - `lib/features/forms/data/services/mdot_0582b_test_numbering_service.dart`
    - verification after patch:
      - `flutter analyze` on touched row/filler/numbering files: green
      - `flutter test test\features\forms\data\pdf\mdot_0582b_pdf_filler_test.dart test\features\forms\data\services\mdot_0582b_test_numbering_service_test.dart test\features\forms\services\form_export_mapping_matrix_test.dart`: green (`+31`)
    - real-auth Samsung re-verification after patched APK install:
      - rebuilt with
        `flutter build apk --debug --dart-define-from-file=.env --target-platform android-arm64`
      - installed on Samsung `RFCNC0Y975L` with no mock auth
      - app shell now shows the stale draft as `Test #1` / `Enter test row`
        instead of treating the old blank seed row as a sent test
      - preview evidence:
        `.codex/artifacts/2026-04-10/device_validation/62_0582b_preview_after_blank_seed_fix.png`
      - preview UI dump shows `EditText` count `0`, `Test Results` count `0`,
        and single occurrences of `2594`, `5.72`, and `130.2`
      - exported PDF evidence:
        `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_after_blank_seed_fix_device_export.pdf`
  - 2026-04-10 reopened regression finding and fix:
    - after blank-row repair, the hub hydration path could still wipe persisted
      0582B standards because empty draft controller values were normalized and
      then blindly `addAll`-merged over non-empty persisted response values
    - patched owner:
      - `lib/features/forms/data/services/mdot_0582b_standards.dart`
      - `lib/features/forms/presentation/controllers/mdot_hub_controller_hydration.dart`
    - added regression:
      - `test/features/forms/services/mdot_0582b_standards_test.dart`
    - verification:
      - `flutter analyze` on the touched standards/hydration/test files:
        green
      - `flutter test test\features\forms\services\mdot_0582b_standards_test.dart test\features\forms\data\pdf\mdot_0582b_pdf_filler_test.dart test\features\forms\services\form_export_mapping_matrix_test.dart`:
        green (`+28`)
    - final real-auth Samsung 0582B proof:
      - preview XML had `EditText` count `0`, standards values present, F/G/H
        present, and no row-zero text hit
      - pulled export
        `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_seeded_after_standards_fix_device_export.pdf`
        had `2Row1=1`, `ARow1=1`, `FRow1=2594`, `GRow1=5.72`,
        `HRow1=130.2`, chart standards in `DENSITYRow1/DENSITYRow2` and
        `MOISTURERow1/MOISTURERow2`, and operating standards in
        `DENSITYRow1_2/MOISTURERow1_2`
      - rendered export proof:
        `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_after_blank_seed_fix_device_export_page_1.png`
      - pulled export raw field inspection:
        - `ARow1=1`
        - `BRow1=8`
        - `CRow1=.0439`
        - `DRow1=4600`
        - `ERow1=2006`
        - `FRow1=2594`
        - `GRow1=5.72`
        - `HRow1=130.2`
        - `ARow2/BRow2/CRow2/DRow2/ERow2/FRow2/GRow2/HRow2` are empty
        - chart standards remain `131.5/132.5` and `7.5/8.5`
        - operating standards remain `130.0` and `7.5`
      - `REMARKS 1` is empty
  - 2026-04-10 double-text / row-zero regression finding and fix:
    - user reported the current 0582B output still looked double-written and
      the test number appeared as `0`
    - patched owners:
      - `lib/features/forms/data/services/form_pdf_rendering_service.dart`
      - `lib/features/forms/data/services/mdot_0582b_display_formatter.dart`
      - `lib/features/forms/data/pdf/mdot_0582b_pdf_filler.dart`
      - `lib/features/forms/presentation/widgets/form_viewer_sections.dart`
      - `lib/features/forms/presentation/widgets/hub_compact_accordion_sections.dart`
      - `lib/features/forms/presentation/widgets/hub_expanded_section_content.dart`
      - `lib/features/forms/presentation/widgets/hub_proctor_content.dart`
      - `.codex/scripts/generate_pdf_fidelity_artifacts_test.dart`
    - repair details:
      - registry-backed PDF fillers now skip the generic field/table fallback
        writer so registered forms cannot receive both the form-specific
        writer output and a second generic field/table pass
      - 0582B row-number rendering now falls back to the one-based PDF row for
        stale `0`, blank, or invalid values in both the PDF filler and
        hub/form display surfaces
      - the synthetic artifact fixture no longer includes an unrelated
        right-offset `0`, so proof artifacts do not visually obscure a row
        number regression
    - verification:
      - `flutter analyze` on touched 0582B/PDF/widget files: green
      - `flutter test test\features\forms\data\services\mdot_0582b_test_numbering_service_test.dart test\features\forms\data\pdf\mdot_0582b_pdf_filler_test.dart test\features\forms\services\form_export_mapping_matrix_test.dart test\features\forms\services\form_pdf_field_writer_test.dart`:
        green (`+33`)
      - `.codex/scripts/generate_pdf_fidelity_artifacts_test.dart`: green
      - regenerated synthetic export proof has `2Row1=1`, `ARow1=1`, no
        zero-valued row-number fields, and `F/G/H=2594/5.72/130.2`
      - regenerated synthetic flattened preview proof has no AcroForm fields
        and exactly one occurrence each of `2594`, `5.72`, and `130.2`
      - runtime code search under `lib`, `android`, `ios`, and `assets` found
        no `MOCK_AUTH`, `mockAuth`, autologin, `Test User`, or
        `test@example.com` strings
      - fresh real-auth Samsung APK was built and installed on device
        `RFCNC0Y975L`; package dump showed `versionCode=3`,
        `versionName=0.1.2`, and `lastUpdateTime=2026-04-10 17:39:47`
      - first launch after install restored an old preview route, so it was
        force-stopped and not counted as valid evidence
      - clean relaunch opened the real project-backed app, then
        `Toolbox -> Forms -> Saved -> MDOT 0582B -> Preview PDF` regenerated
        preview evidence at:
        `.codex/artifacts/2026-04-10/device_validation/142_0582b_preview_after_double_text_row_zero_fix.png`
        and
        `.codex/artifacts/2026-04-10/device_validation/142_0582b_preview_after_double_text_row_zero_fix.xml`
      - preview XML had `EditText` count `0`, no `Test Results:` text, no
        `Test #0`, no generic `DENSITYRow` field-name leak, and the expected
        0582B values present
      - exported device proof was pulled to:
        `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_after_double_text_row_zero_fix_device_export.pdf`
      - exported AcroForm inspection showed `2Row1=1`, `ARow1=1`,
        `BRow1=8`, `CRow1=.0439`, `DRow1=4600`, `ERow1=2006`,
        `FRow1=2594`, `GRow1=5.72`, `HRow1=130.2`,
        `DENSITYRow1=131.5`, `DENSITYRow2=132.5`,
        `MOISTURERow1=7.5`, `MOISTURERow2=8.5`,
        `DENSITYRow1_2=130.0`, and `MOISTURERow1_2=7.5`
      - exported AcroForm inspection found no `2Row*` or `ARow*` field with
        value `0`; the remaining `14Row1=0` is a valid offset/distance field,
        not a test/proctor number
  - 2026-04-10 post-review follow-up:
    - read-only review found two concrete gaps after the first double-text
      repair:
      - preview cache keys did not include parsed header data, so header-only
        edits could show stale preview output
      - stale zero-number proctor rows containing only `weights_20_10` no
        longer wrote literal `0`, but could still normalize into a duplicate
        visible proctor row `1` and push the real proctor row to row 2
    - patched owners:
      - `lib/features/forms/data/services/form_state_hasher.dart`
      - `lib/features/forms/data/services/form_pdf_service.dart`
      - `lib/features/forms/data/models/form_response.dart`
      - `lib/features/forms/data/pdf/mdot_0582b_pdf_filler.dart`
      - `test/features/forms/services/form_state_hasher_test.dart`
      - `test/features/forms/data/models/form_response_test.dart`
      - `test/features/forms/data/pdf/mdot_0582b_pdf_filler_test.dart`
      - `test/features/forms/services/form_export_mapping_matrix_test.dart`
    - verification:
      - `flutter analyze` on touched cache/model/filler/test files: green
      - `flutter test test\features\forms\services\form_state_hasher_test.dart test\features\forms\data\models\form_response_test.dart test\features\forms\data\pdf\mdot_0582b_pdf_filler_test.dart test\features\forms\services\form_export_mapping_matrix_test.dart`:
        green (`+66`)
      - artifact generator after review fixes: green
      - fresh APK installed on Samsung `RFCNC0Y975L`, SHA256
        `CE55975FBA7084B728AEAB6EB67E38E12D144F2C05A97C6B32C152045E3C45AE`
      - current 0582B preview proof:
        `.codex/artifacts/2026-04-10/device_validation/159_0582b_preview_after_review_fix.png`
        and
        `.codex/artifacts/2026-04-10/device_validation/159_0582b_preview_after_review_fix.xml`
      - current 0582B export proof:
        `.codex/artifacts/2026-04-10/device_validation/MDOT_0582B_after_review_fix_device_export.pdf`
      - current export field inspection:
        - `2Row1=1`
        - `2Row2` is empty
        - `ARow1=1`
        - `ARow2/BRow2/FRow2/GRow2/HRow2` are empty
        - `BRow1=8`
        - `CRow1=.0439`
        - `DRow1=4600`
        - `ERow1=2006`
        - `FRow1=2594`
        - `GRow1=5.72`
        - `HRow1=130.2`
        - no `2Row*` or `ARow*` field has value `0`
    - final all-form preview/export re-verification on the same APK is now
      recorded in
      `.codex/plans/2026-04-10-form-fidelity-device-validation-spec.md`
- 0582B export snapshot correction:
  - export must flush the same current hub draft snapshot used by preview
    before invoking the shared export flow, so proctor B-H values do not appear
    in preview and disappear from the exported PDF
- Final closure rule:
  - implement the full spec
  - verify each slice as it lands
  - review the implementation after the first green verification pass
  - then run one final all-forms end-to-end re-verification across preview and
    reopened export on the real-auth Samsung device
