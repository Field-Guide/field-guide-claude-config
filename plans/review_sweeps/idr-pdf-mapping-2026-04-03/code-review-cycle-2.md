# Code Review — Cycle 2

**Verdict**: REJECT (1 critical already fixed, 3 significant)

## Cycle 1 Resolution: 12/12 addressed (1 partial — catch block in activitiesDisplayText)

## Remaining Issues

**C1 (CRITICAL): `catch (_)` in activitiesDisplayText (line 552)** — ALREADY FIXED between cycles

**S1: Signature field regression (line 913)**
- Plan drops `data.entry.signature ??` fallback, replacing with just `data.inspectorName`
- Fix: Keep `data.entry.signature ?? data.inspectorName`

**S2: `_isEmptyDraft()` in screen only checks active controller (line 704)**
- After changes, `activitiesController` returns only active location's controller
- Entry with text in non-active location treated as empty → silent deletion
- Fix: Delegate to `_editingController.isEmptyDraft` instead

**S3: A23 lint — inline TextStyle in presentation widget (line 482)**
- `TextStyle(fontStyle: FontStyle.italic)` in orphaned chip
- Fix: Use `tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic)` from textTheme
