# Defects: Tooling & Process

## Active Patterns

### [CONFIG] 2026-04-02: Windows path normalization missing in lint rules
**Pattern**: 8 path-scoped lint rules used `resolver.path.contains('/presentation/')` without normalizing backslashes. On Windows, `resolver.path` uses `\`, so the check never matched — rules silently skipped. CI (Linux) caught 93 violations that local saw 24.
**Prevention**: ALL path-scoped lint rules MUST normalize paths first: `final filePath = resolver.path.replaceAll('\\', '/');`. Verify local/CI parity after creating any path-scoped rule.
**Ref**: Session 706. Rules A3, A4, A5, A6, A8, A13, A15, D5 all affected.

### [CONFIG] 2026-04-02: Grep checks catch lint rule source code as violations
**Pattern**: Pre-commit grep check for `AUTOINCREMENT` flagged the lint rule file that checks for AUTOINCREMENT (the rule contains the string as a literal). Same for `sync_control` grep catching lint rule doc comments.
**Prevention**: Grep checks in pre-commit and CI must exclude `fg_lint_packages/` from scanning. Lint rule files naturally contain the patterns they check for.
**Ref**: Session 706. `grep-checks.ps1` Check 5 (AUTOINCREMENT) and Check 1 (sync_control).

### [CONFIG] 2026-04-01: Destructive git checkout on uncommitted work
**Pattern**: `git checkout -- <dir>` used to "revert" a few damaged files, but wiped ALL unstaged changes in those directories — including days of unrelated work from sessions 697-698 (~90+ files).
**Prevention**: NEVER use `git checkout --`, `git restore`, `git reset --hard`, or `git clean` on directories with uncommitted work. Use `git stash` first if you must revert. Better: only revert the SPECIFIC damaged files by name, not entire directories.
**Ref**: Session 699. Root cause: PowerShell `Set-Content -NoNewline` collapsed file newlines, then `git checkout -- lib/ test/ integration_test/` destroyed everything.

### [CONFIG] 2026-04-01: PowerShell Set-Content destroys file formatting
**Pattern**: `Set-Content -NoNewline` combined with regex replacement strips all newlines from files, collapsing multi-line Dart files into single lines (24k+ analyze errors).
**Prevention**: NEVER use PowerShell `Set-Content` for mass file edits. Use Python with explicit line-by-line processing and preserved line endings. Test on 1 file first before batch operations.
**Ref**: Session 699. 468 files corrupted before git checkout compounded the damage.

### [CONFIG] 2026-04-01: Uncommitted work across sessions
**Pattern**: Sessions 681-698 accumulated changes without committing. When disaster struck, 18 sessions of work were at risk with no safety net.
**Prevention**: Commit at the end of every session, even as WIP on a feature branch. `git add -A && git commit -m "WIP: session N"` takes 5 seconds and creates a recovery point.
**Ref**: Session 699. Only reason partial recovery was possible was a dangling stash commit from an earlier auto-stash.
