# Forms Infrastructure Plan Review — Round 1

**Date**: 2026-03-28
**Plan**: `.claude/plans/2026-03-28-forms-infrastructure.md`
**Spec**: `.claude/specs/2026-03-28-forms-infrastructure-spec.md`

## Review Agents

### Security Agent: REJECT
- **SEC-F01 CRITICAL**: Storage bucket RLS uses `foldername[1]` instead of `[2]` — all storage access broken
- **SEC-F02 HIGH**: Missing `TO authenticated` on all policies
- **SEC-F03 HIGH**: Missing `NOT is_viewer()` on write policies
- **SEC-F04 HIGH**: INSERT policy allows anyone to create builtins
- **SEC-F05 MEDIUM**: No filename sanitization for documents
- **SEC-F06 MEDIUM**: No file type allowlist enforcement in repository
- **SEC-F07 MEDIUM**: cascade SECURITY DEFINER note
- **SEC-F08 LOW**: nullable created_by_user_id

### Completeness Agent: REJECT
- **FINDING 1 (Must Fix)**: Export flow never creates FormExport/EntryExport metadata rows
- **FINDING 2 (Must Fix)**: Document attachment flow completely missing (no FilePicker, no UI, no Document creation)
- **FINDING 3 (Must Fix)**: Bucket name mismatch — migration creates `documents` but adapters reference `entry-documents`
- **FINDING 4 (Minor)**: ~6 unaddressed hardcoded 0582B references need acknowledgment

### Code Review Agent: Pending (92 turns, likely context-limited)

## Remediation Plan

All findings addressed in fix sweep below.
