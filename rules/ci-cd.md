---
paths:
  - ".github/workflows/**"
---

# CI/CD

- Keep `quality-gate.yml` as the blocking source of truth for analysis, lint, test, and security checks.
- Do not weaken CI by downgrading checks, widening allowlists, or adding bypass comments to satisfy a change.
- Use GitHub Actions logs to debug CI behavior before changing workflow logic.
