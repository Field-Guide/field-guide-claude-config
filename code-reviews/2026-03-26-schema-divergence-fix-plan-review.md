# Schema Divergence Fix — Plan Review Report

**Date:** 2026-03-26
**Plan:** `.claude/plans/2026-03-26-schema-divergence-fix.md`

## Round 1 Results

### Code Review: REJECT → Fixed
| # | Severity | Finding | Status |
|---|----------|---------|--------|
| 1 | CRITICAL | Soft-deleted assignments still grant project SELECT access (tighten_project_select_rls policy) | FIXED — Added FIX 6 to migration: re-create company_projects_select with deleted_at IS NULL |
| 2 | HIGH | UPDATE RLS WITH CHECK doesn't enforce column immutability | FIXED — Added FIX 5: lock_assignment_columns() BEFORE UPDATE trigger |
| 3 | HIGH | project_assignments missing from _directChildTables | FIXED — Added Step 3.5 |
| 4 | MEDIUM | conflict_log in test fixture missing conflict_count | Noted — not blocking |
| 5 | MEDIUM | SqliteTestHelper uses version 37 | Noted — not blocking |
| 6 | MEDIUM | replaceAllForProject doesn't filter soft-deleted | FIXED — Added Step 3.4 |
| 7 | MEDIUM | project_assignment_test.dart doesn't validate new fields | Noted — backward compatible |

### Security Review: APPROVE WITH CONDITIONS → Fixed
| # | Severity | Finding | Status |
|---|----------|---------|--------|
| H-1 | HIGH | Soft-deleted assignments grant project visibility | FIXED — Same as CRITICAL-1 above |
| H-2 | HIGH | Column immutability not enforced | FIXED — Same as HIGH-2 above |
| M-1 | MEDIUM | Undelete path open via stamp_deleted_by NULL transition | NOT AN ISSUE — WITH CHECK blocks undelete |
| M-2 | MEDIUM | Deleted assignments visible via SELECT | INTENTIONAL — client-side filters exclude them |
| M-3 | MEDIUM | Two BEFORE INSERT triggers (enforce_created_by + enforce_assigned_by) | OK — independent columns |

## Round 2 Results

### Code Review: APPROVE
- All Round 1 CRITICAL/HIGH fixes verified correct
- Ground truth: all string literals match actual source (27/27 checks passed)
- Minor: line number drift on getByUser (29→28) and getAssignedProjectIds (40→39) — code blocks are exact matches

### Security Review: APPROVE
- Defense-in-depth chain confirmed solid: RLS → triggers → no gaps
- Trigger ordering verified correct (alphabetical: lock_created_by → lock_columns → stamp_deleted_by → updated_at)
- No privilege escalation paths
- Two LOW findings:
  - L-1: project_assignments missing from purge_soft_deleted_records() — table bloat over time, no security impact. Defer to backlog.
  - L-2: Removed tautological `project_id = project_id` from WITH CHECK (was dead code)

## Final Verdict: APPROVED (2 rounds, 2 code + 2 security reviews)
