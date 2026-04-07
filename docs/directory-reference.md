# .claude Directory Reference

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `plans/` | Active implementation plans |
| `prds/` | Product requirement documents |
| `specs/` | Design and implementation specs |
| `agents/` | Claude-role definitions |
| `skills/` | Workflow skills |
| `rules/` | Path-scoped implementation constraints |
| `docs/` | Live feature docs, guides, and architecture references |
| `architecture-decisions/` | Feature constraints and architectural invariants |
| `autoload/` | Current session handoff state |
| `memory/` | Persistent project memory |
| `code-reviews/` | Historical review outputs |
| `hooks/` | Validation and pre-commit scripts |
| `test-results/` | Saved verification runs |
| `tailor/` | Structured spec-analysis output |
| `adversarial_reviews/` | Spec-level challenge reviews |
| `backlogged-plans/` | Deferred planning work |
| `outputs/` | Audit output reports |
| `user-notes/` | Raw user notes |

## Design-System Reference

`lib/core/design_system/` is the live UI foundation. The current branch assumes:
- tokens are ThemeExtensions
- only light and dark themes are supported
- raw `Scaffold`, `AlertDialog`, `showDialog`, `showModalBottomSheet`,
  `Colors.*`, hardcoded spacing/radius/duration, and inline `TextStyle` are
  lint-banned in presentation code
- UI/design-system artifacts stay under the 300-line hard ceiling

Primary subdirectories:

| Subdirectory | Purpose |
|--------------|---------|
| `tokens/` | Spacing, radii, motion, shadows, and color ThemeExtensions |
| `atoms/` | Primitive widgets |
| `molecules/` | Composed input/list primitives |
| `organisms/` | Higher-order composed widgets |
| `surfaces/` | Scaffold, sheet, dialog, and container surfaces |
| `feedback/` | Banners, loading, error, and empty states |
| `layout/` | Breakpoints and responsive layout helpers |
| `animation/` | Motion-aware transitions and entrance patterns |

## Driver / Sync Verification Reference

The design-system refactor moved UI verification onto explicit driver contracts.
The current sync-driving surface is:

| Path | Purpose |
|------|---------|
| `lib/main_driver.dart` | Driver entrypoint |
| `lib/core/driver/screen_registry.dart` | Bootstrappable screen builders |
| `lib/core/driver/screen_contract_registry.dart` | Stable UI verification contracts |
| `lib/core/driver/flow_registry.dart` | Declarative navigation and verification flows |
| `lib/core/driver/driver_diagnostics_handler.dart` | Diagnostics endpoints including `/diagnostics/screen_contract` |
| `lib/shared/testing_keys/` | Stable root/action/state keys used by driver flows |

## Quality Gates

Architecture enforcement now comes from both custom lint and scripts:

| Path | Purpose |
|------|---------|
| `fg_lint_packages/field_guide_lints/` | Custom lint package for architecture, sync, data, and test rules |
| `scripts/audit_ui_file_sizes.ps1` | Verifies UI/design-system artifacts stay under 300 lines |
| `.claude/hooks/checks/run-analyze.ps1` | Analyzer gate |
| `.claude/hooks/checks/run-custom-lint.ps1` | Custom lint gate |
| `.claude/doc-drift-map.json` | Mapping for doc updates when code moves |

## Documentation System

Live documentation expected to move with the code:
- `.claude/docs/**`
- `.claude/rules/**`
- `.claude/autoload/_state.md`
- `.claude/memory/MEMORY.md`
- `.claude/doc-drift-map.json`

Historical references stay historical:
- `.claude/code-reviews/**`
- `.claude/plans/completed/**`
- `.claude/logs/**`
- `.claude/test-results/**`
