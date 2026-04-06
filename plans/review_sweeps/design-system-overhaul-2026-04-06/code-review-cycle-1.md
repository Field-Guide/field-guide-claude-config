# Code Review — Design System Overhaul Plan (Cycle 1)

**Verdict: REJECT** — 7 critical + 3 high severity issues

## Critical (7)

**C1. `AppButton.icon()` and `AppButton.text()` factories never defined** — P3 defines only primary/secondary/ghost/danger but P4 references `AppButton.icon(...)` and `AppButton.text(...)` 8+ times.
Fix: Add `icon` and `text` factory constructors to `AppButton` in Step 3.1.1.

**C2. Operator precedence bug in `no_hardcoded_spacing` lint rule** — `&& arg.expression is IntegerLiteral || arg.expression is DoubleLiteral` needs parentheses around the `||`.
Fix: `&& (arg.expression is IntegerLiteral || arg.expression is DoubleLiteral)`

**C3. `AppBannerSeverity` enum referenced but never defined** — P4.15 uses `severity: AppBannerSeverity.warning` but `AppBanner` has no severity parameter.
Fix: Add severity enum to AppBanner, or update P4.15 to use `color:` directly.

**C4. Spec drift: Density variants never implemented** — Spec requires `FieldGuideSpacing` with standard/compact/comfortable variants. Plan only defines `standard`.
Fix: Add `compact` and `comfortable` static const instances.

**C5. `flutter test` commands in plan** — Steps 6.5.2 and 6.5.4 contain `flutter test`.
Fix: Remove both. Replace with CI-only notes.

**C6. Phase 3 ordering: new atoms reference files not yet moved** — `AppButton` imports co-located atoms, but atoms aren't moved until Sub-phase 3.2.
Fix: Reorder so Sub-phase 3.2 runs BEFORE Sub-phase 3.1.

**C7. `FieldGuideMotion` spec field `curveEmphasized` missing** — Spec lists `curveEmphasized` but plan defines `curveAccelerate`/`curveBounce`/`curveSpring` instead.
Fix: Add `curveEmphasized` field.

## High (3)

**H1. Inconsistent import paths in new P3 components** — New atoms import from `../../theme/` instead of `../tokens/`.
Fix: Use `../tokens/` or tokens barrel.

**H2. `no_raw_snackbar` referenced in P6 lint flip but file doesn't exist** — P0 extended existing `no_direct_snackbar` instead.
Fix: Remove from Step 6.6.2 list.

**H3. Widgetbook created twice with conflicting configs** — P2 and P6 both create `widgetbook/pubspec.yaml`.
Fix: P6 should only add use cases, not recreate skeleton.

## Medium (4)
- M1: ScaffoldWithNavBar uses old import path
- M2: `resizeToAvoidBottomInset: true` is already default — won't fix #201
- M3: Architecture rules doc string numbers are fragile
- M4: ThemeSection RadioGroup import source not noted

## Low (4)
- L1: Missing AST imports in lint rule code blocks
- L2: AppDatePicker creates TextEditingController every build
- L3: Ground truth HC constant line numbers off
- L4: 10 lint rules share boilerplate — opportunity for base class
