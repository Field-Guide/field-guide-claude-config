# Pattern — Custom Lint Rule Authoring

## How the repo does it

Custom lint rules live in `fg_lint_packages/field_guide_lints/lib/<category>/rules/<rule_name>.dart`. Each rule extends `DartLintRule`, declares a `LintCode`, and overrides `run(...)` to walk the AST. Rules are organized under `architecture/`, `sync_integrity/`, `data_safety/`, `test_quality/`. Tests in `fg_lint_packages/field_guide_lints/test/<category>/<rule_name>_test.dart` exercise positive and negative fixtures.

CI runs `dart run custom_lint` and parses violations against a baseline (`lint_baseline.json`). New violations block; baselined violations are tracked via GitHub issues with rule-keyed fingerprints.

## Exemplars

- `fg_lint_packages/field_guide_lints/lib/sync_integrity/rules/push_handler_requires_sync_hint_emitter.dart`
- `fg_lint_packages/field_guide_lints/lib/architecture/rules/screen_registry_contract_sync.dart`
- `fg_lint_packages/field_guide_lints/lib/architecture/rules/max_ui_callable_length.dart`

## Reusable surface

```dart
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MyNewRule extends DartLintRule {
  const MyNewRule() : super(code: _code);

  static const _code = LintCode(
    name: 'my_new_rule',
    problemMessage: 'Human-readable message: what the violation is.',
    correctionMessage: 'Human-readable message: how to fix it.',
    errorSeverity: ErrorSeverity.WARNING, // or ERROR
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      // Walk the AST. Report on the offending node:
      reporter.atNode(node, _code);
    });
  }
}
```

## Registering a rule

Rules are wired into the package plugin in the relevant `*_rules.dart` barrel (`sync_integrity/sync_integrity_rules.dart`, `architecture/architecture_rules.dart`, etc.) and exported from `lib/field_guide_lints.dart`.

## Ownership boundaries

- Rules live in the `field_guide_lints` package only. Do not add analyzer plugins or `ignore_for_file` comments in production code to satisfy a rule — fix the rule or fix the code.
- Tests are required. A rule without positive/negative fixture tests will not pass repo review.
- `lint_baseline.json` exists only for migration. Do not add new rules with a baseline; ship clean or ship behind a feature flag.
- The baseline-aware CI step is the quality gate; it parses violations by `rule:::file` and fails on new counts.

## When this pattern applies to the spec

The sync-hardening initiative should not add lint rules unless a new invariant emerges that existing rules cannot enforce. Most new guardrails (logging event-class coverage, soak gate) are CI scripts, not lint rules. Reach for a lint rule only when the invariant is AST-detectable and the CI script would be fragile.
