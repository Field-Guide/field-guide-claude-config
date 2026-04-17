# Pattern — Python CI Validator Scripts

## How the repo does it

The repo uses Python scripts for cross-file drift validators that run in GitHub Actions. Each script reads Dart or SQL source files, parses narrow regions with regex + hand-rolled bracket matchers, and emits a dashed error list on stderr with exit code 1 on drift. CI runs the script via `python scripts/<name>.py`, pipes stdout to `$GITHUB_STEP_SUMMARY`, fails on non-zero exit.

## Exemplars

- `scripts/validate_sync_adapter_registry.py` — 280 lines, zero dependencies, parses `SyncEngineTables.triggeredTables`, `simpleAdapters`, complex adapter classes, and `registerAdapters([...])` to enforce 6 invariants.
- `scripts/verify_live_supabase_schema_contract.py` — queries Supabase via `supabase db query --db-url`, parses `DatabaseSchemaMetadata.expectedSchema`, confirms RLS + storage policies.
- `scripts/check_changed_migration_rollbacks.py` — git-aware; reads changed files from `git diff`.
- `scripts/validate_migration_rollbacks.py` — pair-matching rollback SQL to forward SQL.

## Reusable surface

```python
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def _strip_comments(source: str) -> str:
    without_blocks = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    return re.sub(r"//.*$", "", without_blocks, flags=re.MULTILINE)

def _extract_bracket_body(source: str, anchor: str, opener: str = "[", closer: str = "]") -> str:
    """Extract the body of a matched-bracket block immediately after an anchor string.
       Handles nested brackets and ignores brackets inside single-quoted strings."""
    # ... see scripts/verify_live_supabase_schema_contract.py for the canonical implementation
```

```python
def validate() -> list[str]:
    errors: list[str] = []
    # ... assertions — append dashed strings to errors on drift
    return errors

def main() -> int:
    try:
        errors = validate()
    except Exception as exc:
        print(f"<name> validation failed: {exc}", file=sys.stderr)
        return 1
    if errors:
        print("<name> drift detected:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("<name> validation passed.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
```

## CI wiring shape

```yaml
- name: <name> validation
  run: |
    python scripts/<name>.py 2>&1 | tee /tmp/<name>.txt || EXIT_CODE=$?
    EXIT_CODE=${EXIT_CODE:-0}
    if [ "$EXIT_CODE" -eq 0 ]; then
      echo "| <name> | :white_check_mark: Pass | <success-msg> |" >> $GITHUB_STEP_SUMMARY
    else
      echo "| <name> | :x: Fail | <fail-msg> |" >> $GITHUB_STEP_SUMMARY
      echo "<details><summary>Output</summary>" >> $GITHUB_STEP_SUMMARY
      echo '```' >> $GITHUB_STEP_SUMMARY
      cat /tmp/<name>.txt >> $GITHUB_STEP_SUMMARY
      echo '```' >> $GITHUB_STEP_SUMMARY
      echo "</details>" >> $GITHUB_STEP_SUMMARY
      exit 1
    fi
```

## Ownership boundaries

- These scripts are hand-rolled parsers, not AST-based. They work because the source files they parse have disciplined shape (single canonical list, single canonical anchor). Don't parse arbitrary Dart.
- Keep scripts stdlib-only. No pip installs. `supabase` CLI is allowed because CI installs it explicitly.
- Exit code 1 on any drift. Stdout lines starting with `-` are the actionable list.
- When the spec calls for PowerShell (`scripts/audit_logging_coverage.ps1`), prefer PowerShell for the canonical entrypoint. Python may be a parallel implementation for cross-platform parity, not a replacement.

## When this pattern applies to the spec

- Phase 4: `scripts/audit_logging_coverage.ps1` (PowerShell canonical; optional `.py` mirror if CI mismatch surfaces).
- Phase 7: `scripts/hash_schema.py` for schema-hash gate. `scripts/github_auto_issue_policy.py` for shared noise policy.
