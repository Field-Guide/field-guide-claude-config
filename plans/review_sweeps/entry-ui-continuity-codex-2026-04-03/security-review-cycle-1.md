# Security Review — Cycle 1

**Verdict: APPROVE with conditions**

## HIGH

**H1: Weather Auto-Fetch Bypasses Entry Ownership Check** (Phase 4.2.1)
- `_autoFetchWeather()` calls `_autoSaveEntry()` without checking `canEditEntry(createdByUserId:)`. A viewer opening another user's entry could trigger weather auto-write.
- Fix: Add ownership check at top of `_autoFetchWeather()`.

## MEDIUM

**M1: Weather Auto-Fetch Defaults ON Without User Consent** (Phase 4.2.1)
- `autoWeatherEnabled` doesn't exist; plan defaults `?? true`, causing automatic location permission requests.
- Fix: Default to `false` (opt-in).

**M2: No Input Validation in New Contractor Creation Form** (Phase 2.3)
- Empty names, whitespace-only names can be submitted.
- Fix: Enforce non-empty after trim, max length ~100 chars.

## Positive

- Calendar read-only simplification removes ~300 lines of editing surface area.
- PDF preview receives in-memory bytes, no file path traversal risk.
- ContractorProvider.createContractor already gates on canWrite().
