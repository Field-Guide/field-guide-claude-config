# Dependency Graph: Automated Quality Gates

**Date**: 2026-03-31
**Spec**: `.claude/specs/2026-03-31-automated-quality-gates-spec.md`

---

## 1. Direct Changes

### 1A. Files to CREATE (New Infrastructure)

#### Lint Package (fg_lint_packages/field_guide_lints/)
| File | Purpose |
|------|---------|
| `fg_lint_packages/field_guide_lints/pubspec.yaml` | Package manifest (deps: custom_lint_builder, analyzer) |
| `fg_lint_packages/field_guide_lints/analysis_options.yaml` | Package-level analysis |
| `fg_lint_packages/field_guide_lints/lib/field_guide_lints.dart` | Plugin entry, registers all rules |
| `fg_lint_packages/field_guide_lints/lib/architecture/architecture_rules.dart` | Barrel export for 17 arch rules |
| `fg_lint_packages/field_guide_lints/lib/architecture/rules/*.dart` | A1-A17 rule implementations |
| `fg_lint_packages/field_guide_lints/lib/data_safety/data_safety_rules.dart` | Barrel export for 12 data rules |
| `fg_lint_packages/field_guide_lints/lib/data_safety/rules/*.dart` | D1-D12 rule implementations |
| `fg_lint_packages/field_guide_lints/lib/sync_integrity/sync_integrity_rules.dart` | Barrel export for 9 sync rules |
| `fg_lint_packages/field_guide_lints/lib/sync_integrity/rules/*.dart` | S1-S9 rule implementations |
| `fg_lint_packages/field_guide_lints/lib/test_quality/test_quality_rules.dart` | Barrel export for 8 test rules |
| `fg_lint_packages/field_guide_lints/lib/test_quality/rules/*.dart` | T1-T8 rule implementations |

#### Pre-Commit Hooks
| File | Purpose |
|------|---------|
| `.claude/hooks/pre-commit.ps1` | REPLACE existing — new orchestrator with analyze+lint+test+grep |
| `.claude/hooks/checks/run-analyze.ps1` | dart analyze check |
| `.claude/hooks/checks/run-custom-lint.ps1` | custom_lint check |
| `.claude/hooks/checks/run-tests.ps1` | Targeted flutter test |
| `.claude/hooks/checks/grep-checks.ps1` | Text pattern checks |

#### CI Workflows
| File | Purpose |
|------|---------|
| `.github/workflows/quality-gate.yml` | Main CI (3 parallel jobs) |
| `.github/workflows/labeler.yml` | PR auto-labeling |
| `.github/workflows/sync-defects.yml` | Defect-to-Issues sync |
| `.github/workflows/stale-branches.yml` | Post-merge branch cleanup |
| `.github/labeler.yml` | Label-to-path mapping config |
| `.github/dependabot.yml` | Weekly pub dependency updates |

### 1B. Files to MODIFY

| File | Line Range | Change |
|------|-----------|--------|
| `analysis_options.yaml` | 1-28 (full rewrite) | Replace `flutter_lints` include with `lints`, enable strict rules, add custom_lint plugin |
| `pubspec.yaml` | 129 | Replace `flutter_lints: ^6.0.0` with `lints: ^5.0.0` + add `custom_lint` dev dep + path dep to lint package |
| `lib/main.dart` | No changes needed | Already clean |

### 1C. Files to DELETE

| File | Reason |
|------|--------|
| `.github/workflows/e2e-tests.yml` | Replaced by `quality-gate.yml` (active jobs: analyze + unit-tests migrate to new workflow) |
| `.github/workflows/nightly-e2e.yml` | Fully deprecated, no active jobs |

### 1D. Bulk Violation Cleanup Files (Phase 2 of spec)

These are the files that must be modified to reach zero violations BEFORE linters are enabled:

#### AppTheme.* → Theme System (797 violations, 76 files)
- All 76 files in `lib/` that reference `AppTheme.*` color constants
- Replace with `Theme.of(context).colorScheme.*`, `FieldGuideColors.of(context).*`, or `AppColors.*` per three-tier system
- `lib/core/theme/app_theme.dart` (line 9, 71KB) — source of deprecated constants (imported by 101 files)

#### Supabase.instance.client → DI (15 violations, 7 files)
- Files with direct `Supabase.instance.client` outside DI root need constructor injection
- DI root: `lib/core/di/app_initializer.dart` (lines 358-882) — legitimate usage

#### DatabaseService() direct construction (3 violations)
- `lib/features/sync/data/datasources/background_sync_handler.dart`
- `lib/features/auth/data/datasources/remote/user_profile_sync_datasource.dart`
- `lib/features/pdf/services/pdf_import_service.dart`

#### catch (_) without logging (20 violations, 9 files)
- Add `Logger.<category>()` calls in catch blocks

#### Hardcoded Key('...') in runtime (12 violations, 5 files)
- Replace with `TestingKeys.*` references

#### TestingKeys bypasses (41 violations, 12 files)
- Replace direct `*TestingKeys.*` sub-key usage with `TestingKeys.*` facade

#### context.read after await (~10 violations)
- Add `if (!mounted) return;` guards

#### ConflictAlgorithm.ignore without fallback (7 violations outside sync engine)
- Add rowId==0 check with UPDATE fallback

#### Future.delayed in tests (63 violations, 7 files)
- Replace with proper async test patterns

#### Hardcoded Colors.* (8 violations)
- Replace with theme tokens

---

## 2. Key Reference Symbols (for plan-writer context)

### DI Root
- `AppInitializer.initialize()` at `lib/core/di/app_initializer.dart:358-882` — creates all deps, only legitimate place for `Supabase.instance.client`
- `buildAppProviders(AppDependencies deps)` at `lib/core/di/app_providers.dart:37-138` — provider tree composition
- `AppDependencies` at `lib/core/di/app_initializer.dart:267-353` — container with 7 sub-containers

### Theme System
- `AppTheme` at `lib/core/theme/app_theme.dart:9` — 71KB class, deprecated color constants (imported by 101 files)
- `FieldGuideColors` at `lib/core/theme/field_guide_colors.dart` — ThemeExtension with 16 semantic colors (imported by 86 files)
- `AppColors` at `lib/core/theme/colors.dart` — static constants for theme-invariant colors

### Database / Delete Safety
- `GenericLocalDatasource` — base class with built-in `_notDeletedFilter` (used by all entity datasources)
- `SoftDeleteService` at `lib/services/soft_delete_service.dart` — cascade, purge, hardDelete
- `DatabaseService` at `lib/core/database/database_service.dart` — SQLite schema (imported by 91 files)

### Logging
- `Logger` at `lib/core/logging/logger.dart` — categories: sync, pdf, db, auth, ocr, nav, ui, photo, lifecycle, bg, error (imported by 152 files)

### Testing Keys
- `TestingKeys` at `lib/shared/testing_keys/testing_keys.dart` — facade that delegates to 15 sub-key files

### Sync Engine
- `SyncEngine` at `lib/features/sync/engine/sync_engine.dart` — has ConflictAlgorithm.ignore + rowId==0 fallback (reference pattern)
- `SyncRegistry` at `lib/features/sync/engine/sync_registry.dart` — 22 adapters
- `ChangeTracker` at `lib/features/sync/engine/change_tracker.dart` — change_log queries with retry_count filter

### Existing Infrastructure
- `analysis_options.yaml` — currently `include: package:flutter_lints/flutter.yaml` with NO custom rules
- `pubspec.yaml:129` — `flutter_lints: ^6.0.0` (deprecated, to be replaced with `lints: ^5.0.0`)
- `.claude/hooks/pre-commit.ps1` — basic grep-based hook (85 lines), to be replaced
- `.githooks/pre-commit` — bash shim calling PowerShell hook (keep, update path if needed)
- `.github/workflows/e2e-tests.yml` — has active `analyze` + `unit-tests` jobs (migrate to quality-gate.yml)
- `.github/workflows/nightly-e2e.yml` — fully deprecated (delete)

---

## 3. Blast Radius Summary

| Category | Count |
|----------|-------|
| Files to CREATE | ~60 (lint rules + infrastructure) |
| Files to MODIFY (infrastructure) | 2 (analysis_options.yaml, pubspec.yaml) |
| Files to MODIFY (violation cleanup) | ~100+ across all violation categories |
| Files to DELETE | 2 (deprecated CI workflows) |
| Test files affected | ~7 (Future.delayed cleanup) + lint rule tests (~46) |
| Dead code to clean up | `flutter_lints` package removal from pubspec |

---

## 4. Data Flow

```
Developer writes code
        │
        ▼
Pre-Commit Hook (.claude/hooks/pre-commit.ps1)
  ├─ dart analyze (zero errors/warnings)
  ├─ custom_lint (4 packages, 46 rules)
  ├─ grep checks (sync_control, change_log, thresholds, etc.)
  └─ flutter test (changed files only)
        │
        ▼ (push to remote)
GitHub Actions CI (.github/workflows/quality-gate.yml)
  ├─ Job 1: analyze-and-test (full suite)
  ├─ Job 2: architecture-validation (SQL/schema scripts)
  └─ Job 3: security-scanning (DI/delete/sync audits)
        │
        ▼
Branch Protection (main)
  └─ All 3 CI jobs must pass → merge allowed
```

---

## 5. Implementation Order Dependencies

```
Phase 1: analysis_options.yaml Hardening
  └─ Must be FIRST — surfaces violations that Phase 2 fixes

Phase 2: Bulk Violation Cleanup
  ├─ AppTheme migration (biggest, 797 violations)
  ├─ DI migrations (Supabase + DatabaseService)
  ├─ Logging additions (catch blocks)
  ├─ TestingKeys migrations
  ├─ Mounted checks
  ├─ ConflictAlgorithm fixes
  ├─ Test cleanup (Future.delayed)
  └─ Colors.* fixes
  └─ Must reach ZERO violations before Phase 3

Phase 3: Install custom_lint + Create Lint Packages
  ├─ Depends on: Phase 2 (zero violations)
  ├─ fg_lint_packages/field_guide_lints/ (all 46 rules)
  └─ Wire into analysis_options.yaml + pubspec.yaml

Phase 4: Deploy CI + Branch Protection
  ├─ Depends on: Phase 3 (linters working locally)
  ├─ Delete deprecated workflows
  ├─ Create quality-gate.yml, labeler.yml, sync-defects.yml, stale-branches.yml
  ├─ Create .github/labeler.yml, .github/dependabot.yml
  └─ Configure branch protection rules

Phase 5: Pre-Commit Hook Upgrade
  ├─ Depends on: Phase 3 (custom_lint installed)
  └─ Replace .claude/hooks/pre-commit.ps1 with full orchestrator

Phase 6: Cleanup + Rule/Doc Updates
  └─ Update stale rule files per spec Section 16
```
