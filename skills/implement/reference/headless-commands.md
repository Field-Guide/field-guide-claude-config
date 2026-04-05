# Headless CLI Commands

Exact CLI commands for each agent type. All paths MUST be absolute.

**Base path**: `C:/Users/rseba/Projects/Field_Guide_App`

**Auth model**: All agents use `-p` (print mode) which inherits OAuth credentials from the
logged-in `claude` CLI. `--bare` is NOT used because it skips OAuth and requires `ANTHROPIC_API_KEY`.

**Output model**: All agents use `--output-format json` with `--json-schema` for structured output.
The orchestrator extracts `structured_output` from the JSON result using `jq '.structured_output'`.

**Nested session bypass**: `env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_SESSION_ACCESS_TOKEN`
removes parent-session env vars so the child `claude` process starts a clean session with its own OAuth auth.

---

## Implementer (foreground)

```bash
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_SESSION_ACCESS_TOKEN claude \
  -p "PROMPT_HERE" \
  --model sonnet \
  --tools "Read,Edit,Write,Glob,Grep,Bash" \
  --allowedTools "Read,Edit,Write,Glob,Grep,Bash(pwsh*)" \
  --permission-mode acceptEdits \
  --max-turns 80 \
  --output-format json \
  --json-schema '<IMPLEMENTER_SCHEMA>' \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/skills/implement/reference/worker-rules.md" \
  --no-session-persistence \
  2>&1
```

The orchestrator parses `structured_output` from the JSON result via:
```bash
... | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(json.dumps(d.get('structured_output',{})))"
```

Replace the prompt with the phase-specific instructions. The `-p` prompt is constructed inline by the orchestrator — no prompt files.

---

## Reviewer (background, parallel x3)

```bash
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_SESSION_ACCESS_TOKEN claude \
  -p "PROMPT_HERE" \
  --model opus \
  --tools "Read,Glob,Grep" \
  --allowedTools "Read,Glob,Grep" \
  --permission-mode dontAsk \
  --max-turns 40 \
  --output-format json \
  --json-schema '<FINDINGS_SCHEMA>' \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/skills/implement/reference/reviewer-rules.md" \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/agents/<TYPE>-agent.md" \
  --no-session-persistence \
  2>&1
```

Replace `<TYPE>` with one of:
- `completeness-review` (uses `completeness-review-agent.md`)
- `code-review` (uses `code-review-agent.md`)
- `security` (uses `security-agent.md`)

---

## Fixer (foreground)

```bash
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_SESSION_ACCESS_TOKEN claude \
  -p "PROMPT_HERE" \
  --model sonnet \
  --tools "Read,Edit,Write,Glob,Grep,Bash" \
  --allowedTools "Read,Edit,Write,Glob,Grep,Bash(pwsh*)" \
  --permission-mode acceptEdits \
  --max-turns 80 \
  --output-format json \
  --json-schema '<FIXER_SCHEMA>' \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/skills/implement/reference/worker-rules.md" \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/agents/code-fixer-agent.md" \
  --no-session-persistence \
  2>&1
```

---

## JSON Schemas

### Implementer Schema

```json
{
  "type": "object",
  "properties": {
    "phase": { "type": "integer" },
    "status": { "enum": ["done", "failed", "blocked"] },
    "files_created": { "type": "array", "items": { "type": "string" } },
    "files_modified": { "type": "array", "items": { "type": "string" } },
    "substeps": { "type": "object" },
    "decisions": { "type": "array", "items": { "type": "string" } },
    "lint_clean": { "type": "boolean" },
    "notes": { "type": "string" }
  },
  "required": ["phase", "status", "files_created", "files_modified", "substeps", "decisions", "lint_clean"]
}
```

### Findings Schema (all 3 reviewer types)

See `findings-schema.json` for the canonical schema.

### Fixer Schema

```json
{
  "type": "object",
  "properties": {
    "findings_received": { "type": "integer" },
    "findings_fixed": { "type": "integer" },
    "findings_skipped": { "type": "integer" },
    "skipped_reasons": { "type": "array", "items": { "type": "string" } },
    "files_modified": { "type": "array", "items": { "type": "string" } },
    "lint_clean": { "type": "boolean" }
  },
  "required": ["findings_received", "findings_fixed", "findings_skipped", "files_modified", "lint_clean"]
}
```

---

## Common Flags

| Flag | Purpose |
|------|---------|
| `env -u CLAUDECODE ...` | Remove parent-session env vars so child authenticates independently |
| `-p` | Print mode — non-interactive, inherits OAuth from `~/.claude/.credentials.json` |
| `--model` | `sonnet` for implementers/fixers, `opus` for reviewers |
| `--tools` | Declares available tools per agent type |
| `--allowedTools` | Auto-approved tools (no permission prompts) |
| `--permission-mode` | `acceptEdits` for writers, `dontAsk` for read-only |
| `--max-turns` | Prevents runaway agents (80 implementers/fixers, 40 reviewers) |
| `--output-format json` | Structured JSON with `structured_output` field |
| `--json-schema` | Structured output schema — agent returns typed JSON in `structured_output` |
| `--append-system-prompt-file` | Injects static rules (worker/reviewer) + agent definition |
| `--no-session-persistence` | Ephemeral — don't pollute session history |
