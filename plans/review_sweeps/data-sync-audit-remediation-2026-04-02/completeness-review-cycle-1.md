# Completeness Review: Data, Database & Sync Audit Remediation Plan

**Plan**: `.claude/plans/2026-04-02-data-sync-audit-remediation.md`
**Spec**: `.claude/specs/2026-04-02-data-sync-audit-remediation-spec.md`
**Ground Truth**: `.claude/tailor/2026-04-02-data-sync-audit-remediation/ground-truth.md`
**Reviewer**: Completeness Agent
**Date**: 2026-04-01
**Cycle**: 1
**Verdict**: **REJECT** — 2 HIGH, 2 MEDIUM, 2 LOW findings

---

## Requirements Coverage

| Req | Description | Status | Notes |
|-----|-------------|--------|-------|
| R1 | F10: Remove unused userId param | MET | Sub-phase 1.1 |
| R2 | F12: Delete dead query_mixins.dart | MET | Sub-phase 1.2 |
| R3 | F13: Delete stale sync_queue test | MET | Sub-phase 1.3 |
| R4 | BLOCKER-38: Delete clearLocalCompanyData + SwitchCompanyUseCase | MET | Sub-phase 1.4 |
| R5 | F3: Remove form_type DEFAULT via migration | MET | Sub-phase 2.1 |
| R6 | F3: Audit all INSERT INTO form_responses call sites | NOT MET | Plan omits this entirely |
| R7 | F3: Update SchemaVerifier expectedSchema | MET | Step 2.1.4 |
| R8 | F11: SchemaVerifier report-only | MET | Sub-phase 2.2 |
| R9 | F4/F7: Extend UserCertificationLocalDatasource | MET | FLAG-1 correctly handled |
| R10 | F4/F7: Refactor UserProfileSyncDatasource | MET | Step 3.1.5 |
| R11 | F4/F7: Inject cert datasource | DRIFTED | Spec: AuthInitializer; Plan: SyncInitializer |
| R12 | F14: Create EntryContractorsRepository | MET | Sub-phase 3.2 |
| R13 | F14: Update 4 presentation files | MET | Steps 3.2.3-3.2.6 |
| R14 | F14: Register in entries DI | MET | Step 3.2.2 |
| R15 | F5: Extract SyncEngineFactory | MET | Sub-phase 4.1 |
| R16 | F5: SyncOrchestrator uses factory | MET | Step 4.1.4 |
| R17 | F5: BackgroundSyncHandler uses factory | MET | Step 4.1.5 |
| R18 | F9: Builder pattern | MET | Sub-phase 4.2 |
| R19 | F9: Remove 4 setters | MET | Step 4.2.4 |
| R20 | F9: Private constructor | MET | Step 4.2.4 |
| R21 | F9: SyncInitializer uses builder | MET | Sub-phase 4.3 |
| R22 | A6 baseline reduction | MET | Sub-phase 4.3 |
| R23 | BLOCKER-38: Unsynced check in SignOutUseCase | DRIFTED | Plan puts check in dialog widget instead |
| R24 | BLOCKER-38: Three-action dialog | MET | Step 5.2.1 |
| R25 | BLOCKER-38: Update _defects-auth.md | NOT MET | Plan has no step for this |
| R26-R31 | New test files (6) | MET | All covered |
| R32 | forTesting moved to test utility | PARTIALLY MET | Stays on production class with @visibleForTesting |
| R33 | All tests pass, zero analyzer issues | MET | Verification steps throughout |
| R34 | Zero new lint violations | MET | Baseline update steps |

---

## Findings

### HIGH: Missing form_type INSERT call site audit (R6)

**Phase**: 2.1 (F3)

Spec Phase 2 / F3 explicitly requires: "Audit all INSERT INTO form_responses call sites to confirm they already provide explicit form_type — any that don't must be updated." The plan implements the migration but omits this audit step entirely. Without it, the migration could succeed but runtime inserts could fail with NOT NULL constraint violations.

**Fix**: Add a step after 2.1.3 that greps for all `form_responses` insert call sites and verifies each provides explicit `form_type`. Document findings and fix any that don't.

### HIGH: Missing _defects-auth.md update (R25)

**Phase**: 5 (BLOCKER-38)

Spec Phase 5 explicitly requires updating `_defects-auth.md` BLOCKER-38 entry to "mark original data-wipe issue as resolved, reclassify as narrower 'unsynced warning added' closure note." The plan has no step for this.

**Fix**: Add a step (e.g., Step 5.2.3) to update `.claude/defects/_defects-auth.md`.

### MEDIUM: Phase 5 architecture drift (R23)

Spec says "SignOutUseCase checks change_log" returning `UnsyncedChangesResult`. Plan puts check in dialog widget via `context.read<SyncOrchestrator>()`. The plan contains dead code (Step 5.1.1 code that gets reverted in 5.1.2). Clean up the dead steps and explicitly flag the deviation for user approval.

### MEDIUM: forTesting move limitation (R32)

The `super.forTesting()` pattern in 4 of 5 test files requires the constructor to remain on the production class. The `@visibleForTesting` annotation is the correct Dart idiom. Document this as a constraint.

### LOW: Inconsistent test file path (R9/R30)

Sub-phase 3.1 file list references `test/features/auth/data/datasources/local/` but Step 3.1.1 correctly creates at `test/features/settings/data/datasources/local/`. Fix the file list header.

### LOW: Cert datasource injection point drift (R11)

Spec: "Datasource injected via AuthInitializer." Plan: injects via SyncInitializer. Document the rationale (consumer is constructed in SyncInitializer).

---

## FLAG Assessment

- **FLAG-1**: CORRECTLY HANDLED — extends existing datasource
- **FLAG-2**: CORRECTLY HANDLED — table rebuild migration with backfill
- **FLAG-3**: CORRECTLY HANDLED — all 5 files identified and addressed

---

## Summary

- **Requirements:** 34 total, 27 met, 1 partially met, 2 not met, 2 drifted, 2 low deviations
- Fix the 2 HIGH findings, clean up Phase 5 dead code, re-review
