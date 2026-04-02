# Pattern: GitHub Issues from CI

## How We Do It

The `quality-gate.yml` workflow manages GitHub Issues for lint violations using `gh` CLI commands in bash. It lists existing issues, creates/updates as needed, and auto-closes resolved ones. Labels are used for filtering and matching.

## Exemplar: quality-gate.yml (lines 259-308)

### List Existing Issues
```bash
EXISTING_ISSUES=$(gh issue list --label "lint,automated" --state open --json number,title --limit 100 2>/dev/null || echo "[]")
```

### Create New Issue
```bash
gh issue create --title "$TITLE" --body "$BODY" --label "lint,tech-debt,automated" 2>/dev/null || true
```

### Update Existing Issue
```bash
gh issue edit "$ISSUE_NUM" --title "$TITLE" --body "$BODY" 2>/dev/null || true
```

### Close Resolved Issue
```bash
gh issue close "$ISSUE_NUM" --comment "All violations for \`${ISSUE_RULE}\` have been resolved." 2>/dev/null || true
```

### Match Issue by Title Prefix
```bash
ISSUE_NUM=$(echo "$EXISTING_ISSUES" | jq -r ".[] | select(.title | startswith(\"${TITLE_PREFIX}\")) | .number" 2>/dev/null | head -1)
```

## Key Design Decisions in Existing Pattern

1. **`2>/dev/null || true`** on all `gh` commands — graceful failure if GitHub API is unavailable
2. **`--limit 100`** on list — prevents unbounded API calls
3. **Labels for matching** — uses labels to scope issue queries, not just title matching
4. **`--json number,title`** — minimal fields to reduce API payload

## Reusable Methods

| Method | Context | Signature | When to Use |
|--------|---------|-----------|-------------|
| `gh issue create` | quality-gate.yml:289 | `gh issue create --title "T" --body "B" --label "l1,l2"` | Create new GitHub Issue |
| `gh issue close` | quality-gate.yml:302 | `gh issue close NUM --comment "msg"` | Close resolved issue |
| `gh issue edit` | quality-gate.yml:286 | `gh issue edit NUM --title "T" --body "B"` | Update existing issue |
| `gh issue list` | quality-gate.yml:260 | `gh issue list --label "l" --state open --json number,title --limit 100` | Query existing issues |

## Relevance to New Script

The `create-defect-issue.ps1` script translates this bash pattern to PowerShell:
- Same `gh issue create` command, different label scheme
- Validation happens in PowerShell `param()` block instead of bash conditionals
- Returns issue URL via stdout (new — the CI pattern doesn't capture URLs)
