# Code Review — Cycle 1

**Verdict**: REJECT

## Critical Issues

**C1: `_startEditing()` overwrites parsed controllers with raw JSON**
- `entry_activities_section.dart:43` copies `entry.activities` (now JSON) directly to controller text, destroying parsed per-location data
- Fix: Remove the raw copy — controllers are already populated via `populateFrom`/`loadActivitiesJson`

**C2: Non-edit mode displays raw JSON**
- `entry_activities_section.dart:115` shows `entry?.activities` directly — will render raw JSON to user
- Fix: Add display formatter that converts JSON activities to readable text

**C3: `catch (_)` violates lint rule A9** (plan steps 3.1.5, 5.4.1)
- Both `loadActivitiesJson` and `_formatActivitiesForPdf` use silent catch blocks
- Fix: `catch (e) { Logger.data('Activities JSON parse failed: $e'); }`

**C4: `data.entry.weatherCondition` — field doesn't exist** (step 5.3.1)
- Actual field: `data.entry.weather` (type `WeatherCondition?`)
- Fix: Change to `data.entry.weather`

**C5: `data.entry.date!` unnecessary force-unwrap** (step 5.3.1)
- `DailyEntry.date` is non-nullable `DateTime` — `!` is dead code
- Fix: Remove `!`

## Significant Issues

**S1: Missing files in blast radius**
- `lib/core/router/routes/entry_routes.dart` — passes `locationId` to EntryEditorScreen
- `lib/core/driver/flow_registry.dart` — passes `locationId`
- `lib/core/driver/screen_registry.dart` — passes `locationId` (2 sites)
- Fix: Add these to Phase 4.3

**S2: `_isEmptyDraft()` not addressed** — `entry_editor_screen.dart:699` checks `entry.locationId`
- Fix: Add explicit step to remove this check

**S3: `EntryBasicsSection` is dead code** — zero instantiations in codebase
- Fix: Delete file instead of modifying, or note as dead code

**S4: `data.project.projectNumber ?? ''` unnecessary** — field is non-nullable
- Fix: Remove `?? ''`

**S5: Date format silently changed** — existing: `M/d/yy`, plan: `MM/dd/yyyy`
- Fix: Keep existing format or document change with WHY

**S6: Test file inventory incomplete** — key files not enumerated
- Fix: At minimum add verification step: search all test files for `locationId`

**S7: Variable shadowing** — `entry` in `getActivitiesJson()` shadows DailyEntry concept
- Fix: Rename to `mapEntry` or `locEntry`
