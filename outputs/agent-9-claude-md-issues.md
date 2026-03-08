# CLAUDE.md Issues Found by Agent #9 (Skills)

## Issues

1. **`test` skill missing from CLAUDE.md skills table**: `skills/test/SKILL.md` exists on disk but is not listed in the Skills (Agent Enhancements) table.

2. **`audit-config` skill needs to be added to CLAUDE.md skills table**: New skill created at `skills/audit-config/SKILL.md`. Should be added to Skills table.

3. **Fixed broken path in interface-design skill**: `skills/interface-design/references/flutter-tokens.md` referenced `lib/core/theme/spacing.dart` (does not exist). Updated to `lib/core/theme/design_constants.dart`.
