# Worker Rules

Static context for implementer and fixer agents. Appended via `--append-system-prompt-file`.

## Agent Behavior Rules
- NEVER use // ignore: comments — always fix root cause
- NEVER write TODO stubs — every test must have real assertions
- NEVER write dead code — no unused imports, variables, classes
- NEVER run flutter clean
- NEVER add Co-Authored-By lines
- NEVER use Bash for anything except: `pwsh -Command "flutter analyze"`, `pwsh -Command "dart run custom_lint"`
- Read each target file before editing to preserve existing content
- Implement EXACTLY what the plan specifies — no additions, no omissions
- Reuse shared test helpers (check test/helpers/ before creating fakes/mocks)
- All Given/When/Then skeletons MUST be filled with actual test code

## Lint Verification
After completing all implementation substeps, run BOTH:
1. `pwsh -Command "flutter analyze"`
2. `pwsh -Command "dart run custom_lint"`
Fix any violations before reporting completion. NEVER suppress with // ignore:.

## Project Architecture (curated)
- Feature-first Clean Architecture: data/domain/presentation per feature
- State: ChangeNotifier via provider package (~32 providers)
- Data flow: Screen -> Provider -> UseCase -> Repository -> Datasource -> SQLite -> Supabase
- Soft-delete default: delete() = soft-delete, hardDelete() for permanent
- change_log is trigger-only (20 tables, gated by sync_control.pulling='0')
- Provider tiers 1-2 NOT in widget tree (created in AppInitializer)
- is_builtin=1 rows are server-seeded (triggers skip, cascade skip, push skip)
- PRAGMAs via rawQuery (Android API 36 rejects via execute())
- Git Bash silently fails on Flutter — always use `pwsh -Command "..."`

## Lint Rules (key subset)
- No raw SQL in presentation/ or di/
- No datasource imports in presentation/
- No service construction in widgets
- No hardcoded Colors.* in presentation (use theme tokens)
- No raw Scaffold in screens (use AppScaffold)
- No raw AlertDialog/showDialog (use AppDialog.show())
- No silent catch blocks (add Logger call)
- No db.delete() (use soft-delete via datasource)

## Progress Reporting
Print a status line after each sub-step:
```
[PROGRESS] Phase N Step X.Y: DONE — <brief description>
```
