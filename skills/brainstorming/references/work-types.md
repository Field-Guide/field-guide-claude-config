# Work Types — Classification, Stacks, Options

Per-type tailoring for the brainstorming skill. Each primary work type has its own classification signals, per-gate checklist additions (layered on top of the baselines in `intent-capture-gates.md`), CodeMunch exploration picks for Phase 0, and options-phase framings.

## Table of Contents

- [Classification Mini-Gate](#classification-mini-gate)
- [Primary Work Types](#primary-work-types)
  - [1. New Feature](#1-new-feature)
  - [2. Feature Add / Modification](#2-feature-add--modification)
  - [3. Bug Fix](#3-bug-fix)
  - [4. UX Polish](#4-ux-polish)
  - [5. Refactor+](#5-refactor)
- [Secondary Work Types (Generic Gate)](#secondary-work-types-generic-gate)
  - [Security Hardening](#security-hardening)
  - [Data / Schema Migration](#data--schema-migration)
  - [Documentation](#documentation)
- [Classification Snap-back](#classification-snap-back)

## Classification Mini-Gate

Before any Intent questioning, the skill proposes a work-type classification derived from (a) the user's opening message and (b) the Phase 0 baseline outline (`get_repo_outline`, recent git log, `CLAUDE.md`).

**Presentation:**

```
## Work type: <proposed type>

Based on your opening message and the baseline outline, this looks like a **<type>** because:
- <signal 1 from opening message>
- <signal 2 from outline or git log>
- <signal 3 from CLAUDE.md / constraints>

**Reply:**
- `confirmed` — lock the type and run type-aware Phase 0 exploration
- `actually: <other type>` — reclassify (skill re-runs the signals with the new type)
- `unclear: <reason>` — ask more questions before classifying
```

Valid types: `new feature`, `feature add/mod`, `bug fix`, `ux polish`, `refactor+`, `security hardening`, `data/schema migration`, `documentation`. Anything else is a misclassification — push the user to pick one.

**Mid-stream reclassification** is allowed via snap-back: if a later gate surfaces evidence the type is wrong, announce a snap-back to the classification gate and re-run it with the updated signals.

## Primary Work Types

### 1. New Feature

**Signals:** user describes a capability the app does not have today; no existing feature module maps; git log shows no related recent work.

**Phase 0 CodeMunch picks:** `get_repo_outline`, `get_file_tree` (scoped to `lib/features/`), `search_symbols` for any named systems the user referenced, `get_coupling_metrics` on the closest existing feature to surface patterns worth mirroring, `CLAUDE.md` + `lib/features/<closest>/CLAUDE.md` if present.

**Intent stack additions:**
- [ ] **Adjacent feature check** — which existing feature is closest, and does the new one reuse, replace, or live alongside?
- [ ] **Sync surface** — does this introduce new rows, new tables, or only UI on top of existing data?
- [ ] **Terminology mode awareness** — does this respect `AppTerminology` dual-mode (MDOT vs non-MDOT)?

**Scope stack additions:**
- [ ] **New tables vs reuse** — greenfield schema, additive migration, or pure UI?
- [ ] **Builtin vs user-created data** — does this emit `is_builtin=1` rows?
- [ ] **Offline-first expectation** — does the user expect this to fully work offline on day one?

**Vision stack additions:**
- [ ] **Entry point** — where does the user encounter this for the first time (home, project detail, settings, new route)?
- [ ] **Empty state** — what does the first-run screen look like before any data exists?
- [ ] **Discoverability** — how does a user who didn't read release notes find this?

**Options phase — scope options:**
- **A. Minimal v1** — smallest shippable slice that proves the intent
- **B. Full v1** — everything the user described, in one release
- **C. Phased** — v1 ships the core; deferred items land in a follow-up spec with a named dependency

### 2. Feature Add / Modification

**Signals:** user names an existing feature module or screen; asks to change, extend, or adjust it.

**Phase 0 CodeMunch picks:** `search_symbols` for the named feature, `get_file_outline` on the top 2-3 files touched, `get_call_hierarchy` on the primary controller or repository method, `get_coupling_metrics` to reveal blast radius, `get_related_symbols` for siblings that may need matching edits, `git log` scoped to that feature's path.

**Intent stack additions:**
- [ ] **Existing behavior baseline** — does the user's current understanding of how it works match what the outline shows?
- [ ] **Delta vs rewrite** — is this a targeted change, a behavior swap, or a replace-and-deprecate?
- [ ] **Who relies on current behavior** — are there downstream consumers (PDF export, sync, other features) that assume the old shape?

**Scope stack additions:**
- [ ] **Surface area** — UI only, controller logic only, repository/query only, or cross-layer?
- [ ] **Backwards compatibility** — does the old behavior still need to work for existing records?
- [ ] **Migration trigger** — does any data need to be re-normalized, backfilled, or re-exported?

**Vision stack additions:**
- [ ] **Before/after moment** — describe the old flow and the new flow in one sentence each
- [ ] **Discoverability of the change** — does the user need to be told the behavior changed, or should it be invisible?

**Options phase — change-depth options:**
- **A. Surgical** — smallest possible edit; matches existing patterns; minimum blast radius
- **B. Variant** — add a new mode/variant alongside the existing one; existing behavior preserved
- **C. Replace-and-deprecate** — new path becomes default; old path deleted or flagged for removal

### 3. Bug Fix

**Signals:** user describes something that's broken; mentions an error, wrong output, missing data, crash, or regression.

**Phase 0 CodeMunch picks:** `search_symbols` for any error message or class in the bug report, `get_symbol_source` on the suspect function, `get_call_hierarchy` upstream and downstream, `get_changed_symbols` against recent commits (regression?), `get_churn_rate` on the area to see if it's a known-fragile zone, targeted git blame on the suspect lines (via CodeMunch's symbol provenance).

**Intent stack additions:**
- [ ] **Reproduction** — how does the user hit it, exactly? Deterministic or intermittent?
- [ ] **First observed** — when did this start? Which commit / release? Was it ever right?
- [ ] **Blast radius of the bug itself** — who is affected, how often, how badly?
- [ ] **Correct behavior** — what *should* happen? The user's expected output in concrete terms.

**Scope stack additions:**
- [ ] **Symptom vs root cause** — is the user asking for a visible fix or an architectural correction?
- [ ] **Data repair** — do existing wrong records need backfilling, or only new records?
- [ ] **Regression test coverage** — is a test required to lock the fix in, and at what level (unit, widget, driver)?

**Vision stack additions:**
- [ ] **How the user recognizes the fix** — what does "fixed" look like from their seat?
- [ ] **Safety net** — what warning/log/assert should fire if this ever regresses?

**Options phase — fix-shape options:**
- **A. Symptom fix** — patch the visible behavior; fastest; leaves underlying shape alone
- **B. Root-cause fix** — address the real defect; may touch more files; catches related latent bugs
- **C. Restructure** — the bug reveals a bad boundary; fix the shape first, then the symptom follows

### 4. UX Polish

**Signals:** user uses words like "feels", "looks", "layout", "spacing", "tappable", "hard to see", "redesign", "match the new pattern".

**Phase 0 CodeMunch picks:** `search_symbols` in `lib/core/design_system/`, `get_file_outline` on the target screen + any shared widgets it pulls in, `search_text` for raw spacing/color literals that might block the change, confirm which design tokens apply (`FieldGuideSpacing`, `FieldGuideRadii`, `FieldGuideMotion`, `FieldGuideShadows`, `FieldGuideColors`).

**Intent stack additions:**
- [ ] **What feels wrong** — which specific moment fails, in what field condition (gloves, sun, rushed)?
- [ ] **Reference point** — is there another screen in the app that already feels right and should be mirrored?
- [ ] **Observer** — is this the user's own sense, or feedback from a real inspector in the field?

**Scope stack additions:**
- [ ] **Target screens** — exactly which screens/widgets are in scope; what's deliberately out?
- [ ] **Token-only vs structural** — tweaks via design tokens only, or component restructure?
- [ ] **Lint implications** — does any lint rule (no_hardcoded_spacing, no_raw_button, etc.) gate the fix?

**Vision stack additions:**
- [ ] **Side-by-side recognition** — describe how the before and after differ in one sentence each
- [ ] **Accessibility baseline** — contrast, tap target size, dark mode parity — all still pass?

**Options phase — visual directions** *(visual companion earns its keep here):*
- Push 2-3 cards to the browser, each a distinct direction (e.g., "A: Compact chips", "B: Stacked cards", "C: Grid tiles")
- Each card has a short rationale and a wireframe
- User clicks to select; terminal confirms the choice

### 5. Refactor+

**Signals:** user names a structural problem — "this file is too big", "these two classes are tangled", "I want to break this apart", "pull X out of Y".

**Phase 0 CodeMunch picks:** `get_file_outline` + `get_symbol_complexity` on the target file(s), `get_coupling_metrics` for blast radius, `get_dependency_cycles` to surface existing knots, `get_extraction_candidates` for suggestions the tool already computed, `get_hotspots` to confirm the area is worth investing in, `get_layer_violations` if the complaint is about architecture drift.

**Intent stack additions:**
- [ ] **Pain point** — what specifically hurts today? Too big to reason about? Slow builds? Test sprawl? Change fear?
- [ ] **Trigger** — why now? A new feature blocked on it? A recurring bug in the tangled zone? A lint violation ceiling?
- [ ] **Behavior preservation promise** — is any external behavior allowed to change, or is this purely structural?

**Scope stack additions:**
- [ ] **Blast radius limit** — how far is the refactor allowed to reach before stopping?
- [ ] **Test coverage floor** — can the refactor proceed without new tests, or must it land with a coverage net?
- [ ] **Rollback strategy** — single PR, multi-PR, feature-flagged?

**Vision stack additions:**
- [ ] **What the new shape looks like in one sentence**
- [ ] **How the team recognizes it's done** — file count, method size, coupling metric, cycle count?

**Options phase — refactor ambition:**
- **A. Minimum** — smallest split that unblocks the current pain; leave the rest alone
- **B. Single class / single file** — fully refactor one unit; siblings untouched
- **C. Whole subsystem** — the pain is systemic; plan multi-phase refactor (brainstorm covers phase 1 only, later phases get their own specs)

## Secondary Work Types (Generic Gate)

These three share a **generic gate template** instead of their own stacks. They still run the full Intent → Scope → Vision flow, but the per-type additions are a short supplement rather than a dedicated stack.

### Security Hardening

**Signals:** auth / RLS / sync integrity / PII / device enrollment / credential storage / OWASP mobile.

**Generic additions:**
- Intent: *threat model* — who's attacking, what do they get, what's the harm?
- Scope: *in-scope surface* (e.g., "RLS policies on pay_apps only") vs *out-of-scope surface*; always include a `security-review-agent` pass as a constraint.
- Vision: *how does the defense become visible* — logs, audit trail, approval flow, user-visible confirmation?

**Options:** not "fix-shape" or "scope options" — instead offer *defense depth*: **A. Tight patch** (minimal), **B. Layered defense** (patch + monitoring), **C. Policy change** (patch + written policy + review cadence).

### Data / Schema Migration

**Signals:** schema version bump, new table, column rename, backfill, index rebuild, Supabase migration.

**Generic additions:**
- Intent: *why the new shape beats the old shape* — compliance, performance, correctness, or feature enablement?
- Scope: include the 5-file schema-change footprint (database_service, schema/*.dart, schema_verifier, 2 test files); include Supabase migration yes/no; include rollback path.
- Vision: what the user sees during and after migration (loading state, error message, silent success).

**Options:** **A. Additive only** (new column/table, old stays), **B. Additive + backfill** (new + populate historical rows), **C. Destructive rename/drop** (with full rollback plan).

### Documentation

**Signals:** user asks to write, update, or reorganize docs (READMEs, CLAUDE.md, runbooks, skill definitions, onboarding).

**Generic additions:**
- Intent: *who reads this and what do they need* — new engineer onboarding? Future self? Agents via auto-load?
- Scope: what files are in vs out; whether auto-loaded files are touched (they're token-expensive); whether lint or CI validates the docs.
- Vision: how the reader finds the right doc, and how the skill/agent discovers it.

**Options:** **A. Tight edit** (surgical additions), **B. Restructure** (move content between files), **C. New doc** (create from scratch with a clear entry point).

## Classification Snap-back

If Phase 0 exploration or a mid-stream answer reveals the classification is wrong, snap back. Example:

```
## Snap-back: re-confirming work type

You said "fix the delete button on Projects" — I classified this as **bug fix**.
But your latest answer ("I want to pull delete out of the sheet and move it to the new danger-zone section") is really a **feature add/mod** with a visual rearrangement layer.

I'm snapping back to re-confirm the work type before we continue.
```

Then re-present the classification mini-gate with the updated signals. The Intent/Scope/Vision checklists for the new type replace the old stacks on confirmation; any already-answered baseline items carry over, any already-answered type-specific items from the old type are dropped.
