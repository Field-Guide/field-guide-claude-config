# Pattern: Custom Lint Rule

## How We Do It
Lint rules extend `DartLintRule` from `custom_lint_builder`. Each rule has a `_code` constant (`LintCode` with name, problemMessage, correctionMessage, errorSeverity), and a `run()` method that registers AST visitors. Path gating uses `replaceAll('\\', '/')` for Windows compatibility, then `contains()` checks. Design system and test files are always allowlisted.

## Exemplar: NoHardcodedColors (`fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_colors.dart`)

```dart
class NoHardcodedColors extends DartLintRule {
  NoHardcodedColors() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_colors',
    problemMessage:
        'Avoid using hardcoded Colors.* constants. '
        'Use Theme.of(context).colorScheme or design tokens instead.',
    correctionMessage:
        'Replace with the appropriate color from Theme.of(context).colorScheme '
        'to support theming.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path.replaceAll('\\', '/');
    if (!filePath.contains('/presentation/')) return;
    if (filePath.contains('/test/') || filePath.contains('/integration_test/')) return;

    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors' &&
          node.identifier.name != 'transparent') {
        reporter.atNode(node, _code);
      }
    });
  }
}
```

## Exemplar: NoRawScaffold — Instance creation pattern

```dart
context.registry.addInstanceCreationExpression((node) {
  final typeName = node.constructorName.type.name2.lexeme;
  if (typeName == 'Scaffold') {
    reporter.atNode(node.constructorName, _code);
  }
});
```

## Exemplar: NoDirectSnackbar — Method invocation pattern

```dart
context.registry.addMethodInvocation((node) {
  if (node.methodName.name == 'showSnackBar') {
    reporter.atNode(node.methodName, _code);
  }
});
```

## Reusable Methods

| Method | Pattern | When to Use |
|--------|---------|-------------|
| `addInstanceCreationExpression` | Match widget constructor by type name | `no_raw_button`, `no_raw_divider`, `no_raw_tooltip`, `no_raw_dropdown` |
| `addPrefixedIdentifier` | Match prefixed access like `Colors.red` | `no_hardcoded_colors` |
| `addMethodInvocation` | Match method calls by name | `no_raw_snackbar`, `no_raw_navigator` |

## Path Gating Patterns

| Scope | Code |
|-------|------|
| Presentation only | `if (!filePath.contains('/presentation/')) return;` |
| All lib code | `if (!filePath.contains('/lib/')) return;` |
| Exclude tests | `if (filePath.contains('/test/') \|\| filePath.contains('/integration_test/')) return;` |
| Exclude design system | `if (filePath.contains('/core/design_system/')) return;` |
| Exclude specific file | `if (filePath.contains('snackbar_helper')) return;` |

## CRITICAL: Windows Path Normalization
ALL path checks MUST use `resolver.path.replaceAll('\\', '/')` BEFORE any `contains()` check. Windows backslashes break path matching silently.

## Registration
New rules must be added to `architectureRules` list in `fg_lint_packages/field_guide_lints/lib/architecture/architecture_rules.dart`.

## Imports
```dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:custom_lint_builder/custom_lint_builder.dart';
```
