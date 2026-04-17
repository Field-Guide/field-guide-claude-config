# Rerun Notes

Attempt 1 was invalidated because the tablet was unauthenticated at the start of the matrix. Its route/key failures are retained as `coverage-attempt1-invalid.csv` and `findings-attempt1-invalid.jsonl` for audit trail only; trusted results are written to `coverage-clean.csv` and `findings-clean.jsonl`.

Clarified policy applied for this rerun:
- Inspector can view analytics.
- Inspector can edit assigned projects.
- Inspector cannot create/delete/archive projects.
- Inspector cannot view other roles' trash.
- Real sessions/backend only; no MOCK_AUTH.

## Attempt 2 Archive

The first trusted S10 admin sweep found a real crash but then cascaded into noisy missing-control results because the app was stuck in Flutter `ErrorWidget`. Raw output was archived as `coverage-s10-admin-fast-crash-raw.csv` and `findings-s10-admin-fast-crash-raw.jsonl`. The curated blocker and sync finding remain in `findings-clean.jsonl`.
