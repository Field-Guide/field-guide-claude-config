# Tailor Manifest

**Spec**: `.claude/specs/2026-04-06-design-system-overhaul-spec.md`
**Created**: 2026-04-06 12:00
**Files analyzed**: 87
**Patterns discovered**: 8
**Methods mapped**: 42
**Ground truth**: 156 verified, 0 flagged

## Contents
- [dependency-graph.md](dependency-graph.md) — Import chains, upstream/downstream deps for theme/token/design system files
- [ground-truth.md](ground-truth.md) — Verified literals table (routes, keys, columns, symbols, lint paths)
- [blast-radius.md](blast-radius.md) — Impact analysis per symbol + dead code targets
- [patterns/](patterns/) — 8 architectural patterns with exemplars and reusable methods
- [source-excerpts/](source-excerpts/) — Full source organized by file and by spec concern

## Scope Summary

| Category | Count |
|----------|-------|
| Token files (existing + new) | 7 |
| Design system components (existing) | 24 |
| Design system components (new) | 32 |
| Priority decomposition screens | 11 |
| Additional oversized screens | 7 |
| Additional oversized widgets | 8 |
| Shared widgets to move/merge | 7 |
| New lint rules | 10 |
| GitHub issues addressed | 11 |
| HC theme files to delete/update (lib) | 5 |
| HC theme files to delete/update (test) | 12 |
| Phases | 7 (P0-P6) |
