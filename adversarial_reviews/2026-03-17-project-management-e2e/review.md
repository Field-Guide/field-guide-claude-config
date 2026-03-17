# Adversarial Review: Project Management E2E Spec

**Spec**: `.claude/specs/2026-03-17-project-management-e2e-spec.md`
**Date**: 2026-03-17
**Reviewers**: code-review-agent (Opus), security-agent (Opus)

## Code Review Findings

### MUST-FIX
- MF-1: Create-while-offline unspecified → Added offline-aware creation
- MF-2: Failed import leaves broken "My Projects" entry → Added retry/cancel card state
- MF-3: canWrite removal touches 102 occurrences across 24 files → Keep canWrite, add new methods

### SHOULD-CONSIDER (Accepted)
- SC-1: Use local SQLite for Available Projects → Accepted
- SC-2: Orphaned synced_projects cleanup → Added
- SC-4: SyncMutex behavior during import → Documented

### NICE-TO-HAVE (Deferred)
- Sticky section headers, draft detection column, debounce fetchRemoteProjects

## Security Review Findings

### MUST-FIX
- MF-4: Inspector can soft-delete own projects via RLS → Added RLS guard
- MF-5: Raw UPDATE allows column manipulation → Changed to SECURITY DEFINER RPC
- MF-6: CHECK constraint + RPCs still accept 'viewer' → Migration updated

### SHOULD-CONSIDER (Accepted)
- SC-5: Refresh user role on screen open → Added
- SC-6: Limit metadata columns for Available → Accepted
- SC-7: Client-side admin guard on deleteFromSupabase → Added

### NICE-TO-HAVE (Deferred)
- Remove is_viewer() function after migration stabilizes
- Rate limit remote delete calls
- synced_projects on Supabase for cross-device state

## All Findings Applied to Spec
See "Adversarial Review Summary" section at bottom of spec.
