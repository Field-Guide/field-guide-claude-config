# Plan Review: Forms Infrastructure Phase 12 + Addendum Inlining

**Plan**: `.claude/plans/2026-03-28-forms-infrastructure.md`
**Date**: 2026-03-29
**Sweeps**: 2

## Sweep 1 Results

### Code Review: REJECT (3 CRITICAL, 5 HIGH, 5 MEDIUM, 3 LOW)

**CRITICALs (all fixed in sweep 2):**
1. Wrong path `sync/engine/table_adapter` → `sync/adapters/table_adapter` (4 occurrences)
2. Wrong import prefix `tables/` → `schema/` + missing barrel export
3. Phase 6 vs Phase 12.1.4 duplicate modifications to `_childToParentOrder`/`_projectChildTables`

**HIGHs (all fixed in sweep 2):**
4. `schema_verifier.dart` missing column lists for 3 new tables
5. `schema.dart` barrel export (covered by CRITICAL-2 fix)
6. `form_response_id` nullability deviation from spec (documented with NOTE)
7. Phase 6.3 misrepresents `cascadeSoftDeleteEntry` BEFORE state
8. Both `entryChildTables` lists need updating (added Step 6.1.3)

### Security Review: APPROVE with conditions (3 HIGH, 3 MEDIUM, 1 LOW)

**HIGHs (all fixed in sweep 2):**
9. `inject-document-direct` missing release mode guard
10. `inject-document-direct` missing UUID validation
11. `inject-document-direct` missing maxBytes + 10MB limit

**MEDIUMs (noted for implementation):**
- Storage cleanup bucket value not validated against known buckets
- `inspector_forms` UPDATE policy `is_builtin` flip risk (reviewed as acceptable in sweep 2)
- `form_exports` redundant in entry cascade (accepted by design)

## Sweep 2 Results

### Code Review: APPROVE (1 new HIGH, 2 MEDIUM)
- All 11 fixes from sweep 1 verified
- Ground truth: 10/10 spot checks passed
- NEW HIGH: `_entryJunctionTables` not updated → **fixed inline after sweep 2**
- MEDIUM: `_sendJson` await inconsistency (cosmetic)
- MEDIUM: Phase 6.2.2 inspector_forms special-case coupling (noted for implementor)

### Security Review: APPROVE (0 new issues)
- All 3 HIGH fixes verified
- Residual MEDIUM-1 (bucket validation) carried forward — low practical risk
- NEW LOW: Missing WITH CHECK on 3 UPDATE policies — not exploitable due to FK constraints

## Final Status: APPROVED

All CRITICAL and HIGH findings resolved. Remaining MEDIUMs are documented for implementation agents.
