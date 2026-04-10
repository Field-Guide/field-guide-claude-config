---
paths:
  - "android/**/*"
  - "ios/**/*"
  - "pubspec.yaml"
---

# Platform Standards

- Keep Android, iOS, Flutter, and toolchain versions aligned with the current repo configuration. Do not change version pins casually.
- `minSdk` stays at 31 because of `flusseract`.
- Route SQLite `PRAGMA` calls through `rawQuery`, not `execute()`, when touching platform-sensitive database setup.
- Use the repo PowerShell wrappers for Flutter build and test commands instead of running Flutter directly in Git Bash.
