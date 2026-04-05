# Severity Standard

## Severity Levels

| Level | Definition |
|-------|------------|
| CRITICAL | Blocks pipeline. Breaks functionality, security vulnerability, or plan requirement completely missing. |
| HIGH | Significant issue. Wrong behavior, missing error handling. |
| MEDIUM | Quality issue. Suboptimal pattern, missing edge case. |
| LOW | Nitpick. Style, naming, minor improvement. |

ALL severity levels get fixed. No deferrals.

## Finding Format (for reviewers)

Reviewers output findings as structured JSON (see `findings-schema.json`).

Each finding MUST include:

| Field | Description |
|-------|-------------|
| `id` | Sequential identifier (F1, F2, ...) |
| `severity` | One of `critical`, `high`, `medium`, `low` |
| `category` | `completeness`, `code-quality`, or `security` |
| `file` | Absolute path to the affected file |
| `line` | Line number (or `null` if not applicable) |
| `finding` | Clear description of the issue |
| `fix_guidance` | Specific, actionable fix instruction |
| `spec_reference` | Which spec requirement this relates to (completeness only; `null` for code/security) |

## Verdict Rules

- `"approve"` — Zero findings of any severity
- `"reject"` — One or more findings of any severity
