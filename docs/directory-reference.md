# .claude/ Directory Reference

## Directory Structure
| Directory | Purpose |
|-----------|---------|
| plans/ | Implementation plans (active in root, completed in completed/) |
| prds/ | Product Requirements Documents |
| specs/ | Design specifications from brainstorming skill |
| agents/ | Agent definitions (9 agents, all at root level) |
| skills/ | Skill definitions loaded on-demand |
| rules/ | Domain rules with `paths:` frontmatter for lazy loading |
| docs/ | Feature overviews + architecture docs (lazy-loaded by agents) |
| architecture-decisions/ | Feature-specific constraints + shared rules |
| state/ | JSON state files for project tracking |
| defects/ | Per-feature defect tracking (max 5 per feature) |
| memory/ | Detailed project knowledge base (on-demand) |
| autoload/ | Hot session state loaded by `/resume-session` |
| agent-memory/ | Agent-specific persistent memory (auto-managed) |
| logs/ | Archives (state-archive, defects-archive, archive-index) |
| code-reviews/ | Code review reports (auto-saved by code-review-agent) |
| hooks/ | Pre-flight and post-work validation scripts |
| test-results/ | UI test findings per journey run |
| dependency_graphs/ | CodeMunch codebase analysis per plan |
| adversarial_reviews/ | Spec-level adversarial review reports |
| backlogged-plans/ | Deferred/future implementation plans |
| outputs/ | Audit output reports |
| user-notes/ | Raw user notes |

## Documentation System
- `.claude/docs/` — Feature overviews + architecture docs (lazy-loaded by agents)
- `.claude/architecture-decisions/` — Feature-specific constraints + shared rules
- `.claude/state/` — JSON state files; see `state/feature-{name}.json` per feature
- Agents load feature docs on demand via `state/feature-{name}.json`

**Note**: `calculator`, `forms`, `gallery`, `todos` are sub-features of `toolbox` — covered by `feature-toolbox-overview.md` and `feature-toolbox.json`. They do not have separate state/doc files.

## Archives (On-Demand — NOT auto-loaded)
- `.claude/logs/state-archive.md` — Session history
- `.claude/logs/defects-archive.md` — Archived defect entries

## Planning Pipeline
`brainstorming` (spec) → `writing-plans` (plan) → `implement` (execute)
