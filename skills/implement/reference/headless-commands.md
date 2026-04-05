# Headless CLI Commands

Exact CLI commands for each agent type. All paths MUST be absolute.

**Base path**: `C:/Users/rseba/Projects/Field_Guide_App`

---

## Implementer

```bash
unset CLAUDECODE && claude -p "Execute the implementation task described in your system prompt. Write your phase state JSON to the specified path when complete." \
  --model sonnet \
  --allowedTools "Read,Edit,Write,Glob,Grep" \
  --permission-mode dontAsk \
  --max-turns 80 \
  --output-format json \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/phase-N-prompt.md" \
  --no-session-persistence \
  2>&1 | tee "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/phase-N-output.json"
```

Replace `N` with the actual phase number.

---

## Reviewer (completeness / code / security)

```bash
unset CLAUDECODE && claude -p "Execute the review task described in your system prompt. Write your findings JSON to the specified path." \
  --model opus \
  --allowedTools "Read,Glob,Grep,Write" \
  --permission-mode dontAsk \
  --max-turns 80 \
  --output-format json \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/phase-N-review-TYPE-prompt.md" \
  --no-session-persistence \
  2>&1 | tee "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/phase-N-review-TYPE-output.json"
```

Replace `N` with phase number and `TYPE` with `completeness`, `code`, or `security`.

Note: Reviewers need `Write` in allowedTools to write their findings JSON file, but their system prompt restricts them to ONLY write findings files — no source code modification.

---

## Lint Fixer

```bash
unset CLAUDECODE && claude -p "Fix the lint violations described in your system prompt. Run both lint commands after fixing to verify." \
  --model sonnet \
  --allowedTools "Read,Edit,Write,Glob,Grep,Bash(pwsh*)" \
  --permission-mode dontAsk \
  --max-turns 80 \
  --output-format json \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/batch-N-lint-fixer-prompt.md" \
  --no-session-persistence \
  2>&1 | tee "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/batch-N-lint-fixer-output.json"
```

Replace `N` with the batch number.

---

## Review Fixer (per-phase)

```bash
unset CLAUDECODE && claude -p "Fix the review findings described in your system prompt." \
  --model sonnet \
  --allowedTools "Read,Edit,Write,Glob,Grep" \
  --permission-mode dontAsk \
  --max-turns 80 \
  --output-format json \
  --append-system-prompt-file "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/phase-N-fixer-prompt.md" \
  --no-session-persistence \
  2>&1 | tee "C:/Users/rseba/Projects/Field_Guide_App/.claude/outputs/phase-N-fixer-output.json"
```

Replace `N` with the phase number.

Note: Review fixers do NOT run lint. Lint runs at the batch level after fixers complete.

---

## Common Flags

| Flag | Purpose |
|------|---------|
| `unset CLAUDECODE` | Bypass nested-session protection |
| `--model` | `sonnet` for implementers/fixers, `opus` for reviewers |
| `--allowedTools` | Restricts available tools per agent type |
| `--permission-mode dontAsk` | Non-interactive, no permission prompts |
| `--max-turns` | Prevents runaway agents (80 for all agent types) |
| `--output-format json` | Structured output capture |
| `--append-system-prompt-file` | Injects the task-specific prompt |
| `--no-session-persistence` | Ephemeral — don't pollute session history |
| `2>&1 \| tee` | Capture output to file AND display |
