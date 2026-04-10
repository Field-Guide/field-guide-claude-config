# Codex Agent Personas

Use the live Claude agent files as focused review and support personas.

## Live Agents

| Agent | Use For |
|-------|---------|
| `code-review-agent` | correctness, architecture, maintainability, and repo-standard review |
| `security-agent` | auth, tenant boundary, secrets, storage, sync, and platform safety review |
| `completeness-review-agent` | plan or spec fidelity review |
| `debug-research-agent` | scoped read-only bug tracing |
| `plan-writer-agent` | writing plan fragments from prepared tailor output |

## Implementation Note

Implementation work is no longer modeled as a large set of named specialist
agents. Use generic workers, then apply the appropriate rules and reviewer
passes for the touched surface.

## Shared Context Rules

1. Load only the smallest relevant `.claude/` context for the task.
2. Read the matching rule files before reviewing or editing.
3. Keep review scope tight to the current phase or file set.
4. When Codex writes shared artifacts, include `-codex-` in the filename.
