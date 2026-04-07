# Documentation Index

**Restructured**: 2026-02-13
**Updated**: 2026-04-07
**Status**: Live docs aligned to the UI design-system refactor and sync-driver surface

## What Changed

The current live docs now assume the post-refactor architecture:
- design-system tokens and components live under `lib/core/design_system/`
- screens stay thin and compose screen-local controllers through `di/*screen_providers.dart`
- large presentation providers/controllers are split into focused part/helper files
- sync automation drives UI through `lib/core/driver/` contracts, not widget-tree archaeology
- UI/design-system artifacts are expected to stay under the 300-line hard cap

## Organization Overview

### `features/`

Feature docs remain the primary deep reference for current implementation shape.
The architecture pages are the source of truth for:
- root DI wiring via `*_providers.dart`
- screen-local controller scopes via `*screen_providers.dart`
- major provider/controller decompositions
- cross-feature contracts and sync-driving entry points

### `guides/`

Guides cover cross-cutting implementation and testing workflows:
- sync architecture and handler ownership
- analyzer-safe patterns
- E2E / driver testing setup
- manual testing and UI prototyping

### Root docs

Root docs cover the directory map, audit/report material, and the doc-drift
system configuration that tracks which live docs must move when architecture
shifts.

## Current High-Signal Entry Points

- Design system: `lib/core/design_system/`
- Driver surface: `lib/core/driver/screen_registry.dart`
- Driver contracts: `lib/core/driver/screen_contract_registry.dart`
- Driver flows: `lib/core/driver/flow_registry.dart`
- Driver diagnostics: `lib/core/driver/driver_diagnostics_handler.dart`
- UI size audit: `scripts/audit_ui_file_sizes.ps1`
- Custom lints: `fg_lint_packages/field_guide_lints/`
- Drift map: `.claude/doc-drift-map.json`

## Recommended Reading Order

1. Read the relevant feature overview or architecture page in `docs/features/`.
2. Read the matching rules under `.claude/rules/` for constraints.
3. If the task touches sync-driving UI, read:
   - `feature-sync-architecture.md`
   - `rules/testing/patrol-testing.md`
   - `guides/implementation/sync-architecture.md`
4. If the task changes structure, update `.claude/doc-drift-map.json` and the
   affected feature docs in the same change.

## Live vs Historical Material

The following are live references and should track the branch:
- `.claude/docs/**`
- `.claude/rules/**`
- `.claude/autoload/_state.md`
- `.claude/memory/MEMORY.md`
- `.claude/doc-drift-map.json`

Historical reviews, completed plans, archived logs, and prior test results are
intentionally left as historical records and do not need to be rewritten to
match the current branch.

## Related Resources

- `../architecture-decisions/` for feature constraints
- `../rules/` for enforceable implementation rules
- `../prds/` for product intent
- `../specs/` for implementation specs
- `../plans/` for active execution plans
