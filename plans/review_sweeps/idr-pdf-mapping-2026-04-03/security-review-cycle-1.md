# Security Review — Cycle 1

**Verdict**: APPROVE with conditions

## Conditions

1. **MUST**: Replace both `catch (_)` blocks with logging per lint rule A9
2. **MUST**: Add activities display formatting for list screens so raw JSON not rendered
3. **SHOULD**: Document stale `locationName` behavior as known limitation

## Findings

**M1: Silent catch blocks** — `catch (_)` in loadActivitiesJson and _formatActivitiesForPdf
**M2: Raw JSON in UI list screens** — entries_list, home_screen, entry_review show raw JSON text
**L1: No input length validation** — activities JSON could grow unbounded
**L2: Python script hardcoded paths** — acceptable for developer-only tooling

## Security Analysis (All Clear)

- RLS policies scope via `project_id`, not `location_id` — removal is safe
- JSON serialization uses `jsonEncode`/`jsonDecode` — no injection risk
- Sync adapter FK removal is safe — `location_id` already nullable
- `locationName` in JSON is company-scoped, not PII — minimal exposure
- `filterByLocation` is presentation-layer, not access control — safe to remove
