# Tailor Manifest — Sync System Hardening And Harness

**Spec:** `.claude/specs/2026-04-16-sync-system-hardening-and-harness-spec.md`
**Date:** 2026-04-16
**Tailor output root:** `.claude/tailor/2026-04-16-sync-system-hardening-and-harness/`

## What Was Analyzed

- Sync engine core (`lib/features/sync/engine/`, `lib/features/sync/application/`) — `SyncEngine`, `SyncCoordinator`, `SyncErrorClassifier`, `SyncStatus`, `SyncRegistry`, `RealtimeHintHandler`, `SyncHintRemoteEmitter`, pull/push handlers, dirty scope tracker.
- Adapter registry and drift contract (`lib/features/sync/adapters/simple_adapters.dart`, `lib/features/sync/adapters/*_adapter.dart`, `lib/core/database/schema/sync_engine_tables.dart`, `scripts/validate_sync_adapter_registry.py`, `scripts/verify_live_supabase_schema_contract.py`).
- Driver contract surface (`lib/core/driver/screen_registry.dart`, `screen_contract_registry.dart`, `flow_registry.dart`, `driver_diagnostics_handler.dart`).
- Role / RLS / assignment propagation seams (`AuthProvider`, `ProjectProvider`, `ProjectProviderAuthController`, `ProjectAssignmentProvider`, `synced_scope_store`, RLS migrations).
- Logging and observability wiring (`lib/core/logging/logger.dart`, `logger_sentry_transport.dart`, `logger_error_reporter.dart`, `logger_runtime_hooks.dart`, `sentry_runtime.dart`, `sentry_consent.dart`, `sentry_pii_filter.dart`, `lib/main.dart`).
- Existing test surface (`test/features/sync/**`, `test/helpers/sync/**`, `integration_test/**`) and CI (`.github/workflows/quality-gate.yml`, `fg_lint_packages/field_guide_lints/lib/**`).
- Supabase local project shape (`supabase/config.toml`, `supabase/migrations/` — 71 migrations, `supabase/seed.sql` — currently empty).

## What Was Produced

- `manifest.md` — this file.
- `dependency-graph.md` — upstream/downstream map of the surfaces Scope touches.
- `ground-truth.md` — verified file paths, symbols, routes, RPC names, lint rule names, and flagged gaps.
- `blast-radius.md` — affected files and cleanup targets, keyed to Scope phases.
- `patterns/` — reusable implementation patterns.
- `source-excerpts/by-file.md` and `by-concern.md` — only the source snippets writing-plans will need.

## Scope Slices This Tailor Maps

1. Local Docker Supabase + seeded fixture (~10–20 users, multi-project).
2. Harness driver skeleton (real RLS, real Flutter client, role personas).
3. Full-surface correctness matrix.
4. Logging event-class audit + Sentry dual-feed.
5. Property-based concurrency (`glados`) + soak test driver.
6. Sync engine rewrite (targeted hotspots; escape clause for architectural rewrite).
7. Staging Supabase project + CI gate + GitHub auto-issue noise policy.

## Research Gaps (Unresolved)

- `glados` integration patterns: no prior usage in the repo; must be discovered during Phase 5 (PBT) per spec.
- Profiling methodology and tool choice: deferred to the rewrite phase per spec.
- Supabase Log Drain sink format (Logflare / Datadog / custom HTTP): deferred to the Sentry dual-feed phase per spec.
- `scripts/audit_logging_coverage.ps1` does not yet exist; this is a new deliverable (Success criterion 8), not drift.
- `scripts/soak_local.ps1` does not yet exist; this is a new deliverable (Scope), not drift.

## How To Use This Directory

- `ground-truth.md` is the single source of verified literals. Use it before generating new file paths or symbols.
- `patterns/*` hold the implementation shapes the writer should mimic.
- `blast-radius.md` is keyed to the seven-phase sequencing — each phase names the files it will create, modify, or preserve.
- `source-excerpts/` is the minimum set of source snippets the plan writer will need to echo the shapes listed in patterns.
