# Pre-Release Hardening Plan Review

**Date:** 2026-03-29
**Plan:** `.claude/plans/2026-03-29-pre-release-hardening-part{1,2,3}.md`
**Spec:** `.claude/specs/2026-03-29-pre-release-hardening-spec.md`

## Review Verdicts

| Reviewer | Verdict | Key Findings |
|----------|---------|-------------|
| Code Review | REJECT | 6 critical, 4 high, 5 medium |
| Security Review | APPROVE (with conditions) | 0 critical, 2 high, 4 medium |
| Completeness Review | 72/89 covered | 8 critical gaps, 14 partial |

## Critical Fixes Required (consolidated, deduplicated)

### FIX-1: ConsentProvider must use ConsentRepository
- Phase 7 ConsentProvider.acceptConsent() only writes to SharedPreferences
- Must also call ConsentRepository.recordConsent() with 2 rows (privacy_policy, terms_of_service)
- Must accept ConsentRepository + userId in constructor
- Phase 3 data layer is currently dead code

### FIX-2: SupportProvider must use SupportRepository (offline-first)
- Phase 10 SupportProvider.submit() goes directly to Supabase
- Must use SupportRepository to insert locally first
- Must reconcile column names: `log_bundle_path` → `log_file_path`, remove `build_number`, add `platform`
- Phase 4 data layer is currently dead code

### FIX-3: Gate Sentry on consent
- SentryFlutter.init wraps main() unconditionally
- Spec: "neither initializes without acceptance"
- Option: use beforeSend to drop events when consent not accepted
- Or: defer SentryFlutter.init to after consent check in _runApp()

### FIX-4: Remove duplicate dependency/config additions
- sentry_flutter added in Part 1 (^8.13.0) AND Part 2 (^8.12.0) — remove from Part 2
- SENTRY_DSN added to .env.example in Part 1 AND Part 2 — remove from Part 2

### FIX-5: Fix schema mismatches
- SupportTicketStatus: spec says open/acknowledged/resolved, model says open/in_progress/resolved/closed
- Reconcile to one set and update spec, model, migration, and CHECK constraint
- Remove `build_number` from SupportProvider insert (column doesn't exist)
- Rename `log_bundle_path` to `log_file_path` in SupportProvider
- Add `platform` to SupportProvider insert payload

### FIX-6: Fix AppTheme.radiusMd → AppTheme.radiusMedium
- ConsentScreen uses `AppTheme.radiusMd` which doesn't exist
- Replace with `AppTheme.radiusMedium`

### FIX-7: Fix Privacy Policy "encrypted SQLite" claim
- Privacy Policy text claims encrypted SQLite, app uses unencrypted sqflite
- Change to "stored in a local database in the app's private storage directory"

### FIX-8: Create consent records during registration
- Spec: "Consent records created at registration time"
- Phase 7.4 adds checkbox but doesn't write ConsentRecord rows on sign-up
- After successful signUp, insert 2 ConsentRecord rows

### FIX-9: ConsentScreen should load from bundled markdown, not hardcoded Dart strings
- Inline policy text duplicates assets/legal/*.md (DRY violation, divergence risk)
- ConsentScreen should render from same bundled markdown files
- Or: show summary text with links to full documents

### FIX-10: Add "Open in browser" AppBar button on LegalDocumentScreen
- Spec: "Open in browser button in app bar to view hosted version"
- Missing from Phase 11.3

### FIX-11: Add ConsentProvider unit tests
- Spec marks ConsentProvider testing as HIGH priority
- No tests exist in the plan

### FIX-12: Note sync deferral for consent/support tables
- Neither table is wired into SyncOrchestrator
- Add explicit TODO markers and defer to follow-up plan

## Findings to Address During Implementation (not plan fixes)

- Line numbers will drift — search by context strings instead
- `archive` package v4.x API may differ from plan code
- `oss_licenses_flutter` intentionally replaced by LicenseRegistry (conscious deviation)
- Rate limiting on support tickets deferred (spec accepts no throttle)
- Upload size cap on log bundles — add 5MB limit check
