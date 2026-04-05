---
paths:
  - ".github/workflows/**"
---

# CI/CD Rules

## Workflows
4 workflows in `.github/workflows/`:

| Workflow | Jobs | Purpose |
|----------|------|---------|
| `quality-gate.yml` | Analyze+Test, Architecture Validation, Security Scan | Main pipeline (push + PR) |
| `doc-drift.yml` | 1 | Informational drift detection on PRs (never blocks) |
| `stale-branches.yml` | 1 | Auto-delete merged branches |
| `labeler.yml` | 1 | Auto-label PRs |
