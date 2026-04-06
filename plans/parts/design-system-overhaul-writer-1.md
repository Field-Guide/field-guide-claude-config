## Phase 0: Lint Rules

### Sub-phase 0.1: Create `no_raw_button` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_button.dart`

**Agent**: `code-fixer-agent`

#### Step 0.1.1: Create `no_raw_button.dart`

Create the lint rule that catches `ElevatedButton`, `TextButton`, `OutlinedButton`, and `IconButton` usage outside design system and tests.

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_button.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A25: Flags raw button widget usage in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no raw button"
/// Use AppButton instead of raw ElevatedButton/TextButton/OutlinedButton/IconButton.
/// Severity: WARNING
class NoRawButton extends DartLintRule {
  NoRawButton() : super(code: _code);

  static const _code = LintCode(
    name: 'no_raw_button',
    problemMessage:
        'Avoid using raw button widgets (ElevatedButton, TextButton, '
        'OutlinedButton, IconButton). Use AppButton instead.',
    correctionMessage:
        'Replace with AppButton.primary(), AppButton.secondary(), '
        'AppButton.ghost(), or AppButton.icon() from the design system.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  // WHY: These are the four raw Flutter button types that should be wrapped
  // by the design system AppButton component for consistent theming.
  static const _bannedTypes = {
    'ElevatedButton',
    'TextButton',
    'OutlinedButton',
    'IconButton',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // NOTE: Windows path normalization is mandatory — backslashes break contains()
    final filePath = resolver.path.replaceAll('\\', '/');
    // WHY: Only enforce in presentation layer where widgets are built
    if (!filePath.contains('/presentation/')) return;
    // WHY: Tests legitimately construct raw widgets for testing
    if (filePath.contains('/test/') || filePath.contains('/integration_test/')) return;
    // WHY: Design system itself wraps these raw widgets
    if (filePath.contains('/core/design_system/')) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (_bannedTypes.contains(typeName)) {
        reporter.atNode(node.constructorName, _code);
      }
    });
  }
}
```

---

### Sub-phase 0.2: Create `no_raw_divider` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_divider.dart`

**Agent**: `code-fixer-agent`

#### Step 0.2.1: Create `no_raw_divider.dart`

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_divider.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A26: Flags raw Divider usage in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no raw divider"
/// Use AppDivider instead of raw Divider for consistent theming.
/// Severity: WARNING
class NoRawDivider extends DartLintRule {
  NoRawDivider() : super(code: _code);

  static const _code = LintCode(
    name: 'no_raw_divider',
    problemMessage:
        'Avoid using raw Divider. Use AppDivider from the design system '
        'for consistent spacing and color.',
    correctionMessage:
        'Replace Divider() with AppDivider() from the design system barrel.',
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
    if (filePath.contains('/core/design_system/')) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      // NOTE: Catches both Divider and VerticalDivider
      if (typeName == 'Divider' || typeName == 'VerticalDivider') {
        reporter.atNode(node.constructorName, _code);
      }
    });
  }
}
```

---

### Sub-phase 0.3: Create `no_raw_tooltip` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_tooltip.dart`

**Agent**: `code-fixer-agent`

#### Step 0.3.1: Create `no_raw_tooltip.dart`

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_tooltip.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A27: Flags raw Tooltip usage in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no raw tooltip"
/// Use AppTooltip instead of raw Tooltip for consistent theming.
/// Severity: WARNING
class NoRawTooltip extends DartLintRule {
  NoRawTooltip() : super(code: _code);

  static const _code = LintCode(
    name: 'no_raw_tooltip',
    problemMessage:
        'Avoid using raw Tooltip. Use AppTooltip from the design system '
        'for consistent styling and positioning.',
    correctionMessage:
        'Replace Tooltip() with AppTooltip() from the design system barrel.',
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
    if (filePath.contains('/core/design_system/')) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName == 'Tooltip') {
        reporter.atNode(node.constructorName, _code);
      }
    });
  }
}
```

---

### Sub-phase 0.4: Create `no_raw_dropdown` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_dropdown.dart`

**Agent**: `code-fixer-agent`

#### Step 0.4.1: Create `no_raw_dropdown.dart`

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_dropdown.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A28: Flags raw DropdownButton usage in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no raw dropdown"
/// Use AppDropdown instead of raw DropdownButton/DropdownButtonFormField.
/// Severity: WARNING
class NoRawDropdown extends DartLintRule {
  NoRawDropdown() : super(code: _code);

  static const _code = LintCode(
    name: 'no_raw_dropdown',
    problemMessage:
        'Avoid using raw DropdownButton or DropdownButtonFormField. '
        'Use AppDropdown from the design system for consistent theming.',
    correctionMessage:
        'Replace with AppDropdown<T>() from the design system barrel.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _bannedTypes = {
    'DropdownButton',
    'DropdownButtonFormField',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path.replaceAll('\\', '/');
    if (!filePath.contains('/presentation/')) return;
    if (filePath.contains('/test/') || filePath.contains('/integration_test/')) return;
    if (filePath.contains('/core/design_system/')) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (_bannedTypes.contains(typeName)) {
        reporter.atNode(node.constructorName, _code);
      }
    });
  }
}
```

---

### Sub-phase 0.5: Extend existing `no_direct_snackbar` rule

**Files:**
- Modify: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_direct_snackbar.dart`

**Agent**: `code-fixer-agent`

#### Step 0.5.1: Update `no_direct_snackbar.dart` to also catch `SnackBar` constructor

The existing `no_direct_snackbar` already catches `showSnackBar` method invocations. Rather than creating a duplicate `no_raw_snackbar` rule, extend the existing rule to also catch direct `SnackBar` constructor usage (which would indicate someone building a SnackBar widget without using `SnackBarHelper`).

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_direct_snackbar.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A22: Flags direct ScaffoldMessenger.showSnackBar usage AND raw SnackBar
/// construction in presentation files.
///
/// Use SnackBarHelper.show*() instead. Direct snackbar calls are only
/// allowed inside the centralized helper itself.
/// Severity: WARNING
///
/// FROM SPEC: Design System Overhaul Phase 0 - extends existing rule to also
/// catch raw SnackBar constructor usage, avoiding a duplicate no_raw_snackbar rule.
class NoDirectSnackbar extends DartLintRule {
  NoDirectSnackbar() : super(code: _code);

  static const _code = LintCode(
    name: 'no_direct_snackbar',
    problemMessage:
        'Use SnackBarHelper.show*() instead of direct ScaffoldMessenger/'
        'SnackBar calls. The helper provides consistent theming.',
    correctionMessage:
        'Replace with SnackBarHelper.showSuccess/showError/showInfo/showWarning',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path.replaceAll('\\', '/');
    if (!filePath.contains('/lib/')) return;
    if (filePath.contains('/test/') || filePath.contains('/integration_test/')) return;
    if (filePath.contains('/core/design_system/')) return;
    // NOTE: Allow inside the helper itself
    if (filePath.contains('snackbar_helper')) return;

    // WHY: Catches ScaffoldMessenger.of(context).showSnackBar(...)
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'showSnackBar') {
        reporter.atNode(node.methodName, _code);
      }
    });

    // WHY: Also catches direct SnackBar(...) construction outside the helper.
    // This prevents building raw SnackBar widgets that bypass theming.
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName == 'SnackBar') {
        reporter.atNode(node.constructorName, _code);
      }
    });
  }
}
```

---

### Sub-phase 0.6: Create `no_hardcoded_spacing` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_spacing.dart`

**Agent**: `code-fixer-agent`

#### Step 0.6.1: Create `no_hardcoded_spacing.dart`

This rule catches `EdgeInsets.all(N)`, `EdgeInsets.symmetric(...)`, `SizedBox(width: N, height: N)` with numeric literals. It uses `addInstanceCreationExpression` for `SizedBox` and `addMethodInvocation` for `EdgeInsets.*` factory calls.

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_spacing.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A29: Flags hardcoded spacing values in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no hardcoded spacing"
/// Use DesignConstants.space* or FieldGuideSpacing tokens instead of
/// numeric literals in EdgeInsets and SizedBox spacers.
/// Severity: WARNING
class NoHardcodedSpacing extends DartLintRule {
  NoHardcodedSpacing() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_spacing',
    problemMessage:
        'Avoid hardcoded spacing values. Use DesignConstants.space* or '
        'FieldGuideSpacing.of(context).* tokens for consistent spacing.',
    correctionMessage:
        'Replace numeric literals with DesignConstants.space2 (8), '
        'DesignConstants.space4 (16), etc.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path.replaceAll('\\', '/');
    // WHY: Only enforce in presentation layer
    if (!filePath.contains('/presentation/')) return;
    if (filePath.contains('/test/') || filePath.contains('/integration_test/')) return;
    if (filePath.contains('/core/design_system/')) return;

    // WHY: Catches SizedBox(width: 8) and SizedBox(height: 16) spacer patterns.
    // Only flags when width/height args are numeric literals (not variables/constants).
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName == 'SizedBox') {
        for (final arg in node.argumentList.arguments) {
          if (arg is! NamedExpression) continue;
          final name = arg.name.label.name;
          if ((name == 'width' || name == 'height') &&
              arg.expression is IntegerLiteral || arg.expression is DoubleLiteral) {
            reporter.atNode(node.constructorName, _code);
            return; // NOTE: Report once per SizedBox, not per argument
          }
        }
      }
    });

    // WHY: Catches EdgeInsets.all(8), EdgeInsets.symmetric(horizontal: 16),
    // EdgeInsets.only(left: 8) with numeric literal arguments.
    context.registry.addMethodInvocation((node) {
      final target = node.realTarget;
      if (target == null) return;
      // NOTE: EdgeInsets factory methods are static, so the target is a SimpleIdentifier
      final targetName = target is SimpleIdentifier ? target.name : '';
      if (targetName != 'EdgeInsets') return;

      final methodName = node.methodName.name;
      if (methodName == 'all' ||
          methodName == 'symmetric' ||
          methodName == 'only' ||
          methodName == 'fromLTRB') {
        for (final arg in node.argumentList.arguments) {
          final expr = arg is NamedExpression ? arg.expression : arg;
          if (expr is IntegerLiteral || expr is DoubleLiteral) {
            reporter.atNode(node.methodName, _code);
            return; // NOTE: Report once per EdgeInsets call
          }
        }
      }
    });
  }
}
```

**IMPORTANT**: The `addMethodInvocation` approach for `EdgeInsets.*` may need refinement. `EdgeInsets.all(N)` is actually a constructor call (`const EdgeInsets.all(8.0)`), not a method invocation. It will be caught by `addInstanceCreationExpression` instead. The implementing agent should verify by checking which AST node type `EdgeInsets.all(8.0)` produces and adjust accordingly. If it is a constructor call, use:

```dart
context.registry.addInstanceCreationExpression((node) {
  final typeName = node.constructorName.type.name2.lexeme;
  if (typeName == 'EdgeInsets' || typeName == 'SizedBox') {
    // Check for numeric literal arguments
    for (final arg in node.argumentList.arguments) {
      final expr = arg is NamedExpression ? arg.expression : arg;
      if (expr is IntegerLiteral || expr is DoubleLiteral) {
        reporter.atNode(node.constructorName, _code);
        return;
      }
    }
  }
});
```

The implementing agent MUST add the necessary analyzer imports (`NamedExpression`, `IntegerLiteral`, `DoubleLiteral`, `SimpleIdentifier`) from `package:analyzer/dart/ast/ast.dart`.

---

### Sub-phase 0.7: Create `no_hardcoded_radius` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_radius.dart`

**Agent**: `code-fixer-agent`

#### Step 0.7.1: Create `no_hardcoded_radius.dart`

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_radius.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A30: Flags hardcoded BorderRadius values in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no hardcoded radius"
/// Use DesignConstants.radius* or FieldGuideRadii tokens instead of
/// numeric literals in BorderRadius.circular().
/// Severity: WARNING
class NoHardcodedRadius extends DartLintRule {
  NoHardcodedRadius() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_radius',
    problemMessage:
        'Avoid hardcoded radius values in BorderRadius.circular(). '
        'Use DesignConstants.radius* or FieldGuideRadii.of(context).* tokens.',
    correctionMessage:
        'Replace numeric literal with DesignConstants.radiusSmall (8), '
        'DesignConstants.radiusMedium (12), etc.',
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
    if (filePath.contains('/core/design_system/')) return;

    // WHY: BorderRadius.circular(N) is a constructor call.
    // Also catches BorderRadius.all(Radius.circular(N)).
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName == 'BorderRadius') {
        for (final arg in node.argumentList.arguments) {
          final expr = arg is NamedExpression ? arg.expression : arg;
          if (expr is IntegerLiteral || expr is DoubleLiteral) {
            reporter.atNode(node.constructorName, _code);
            return;
          }
        }
      }
    });
  }
}
```

**IMPORTANT**: The implementing agent must add `import 'package:analyzer/dart/ast/ast.dart' show NamedExpression, IntegerLiteral, DoubleLiteral;` at the top of the file.

---

### Sub-phase 0.8: Create `no_hardcoded_duration` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_duration.dart`

**Agent**: `code-fixer-agent`

#### Step 0.8.1: Create `no_hardcoded_duration.dart`

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_hardcoded_duration.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A31: Flags hardcoded Duration values in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no hardcoded duration"
/// Use DesignConstants.animation* or FieldGuideMotion tokens instead of
/// inline Duration(milliseconds: N) in presentation code.
/// Severity: WARNING
class NoHardcodedDuration extends DartLintRule {
  NoHardcodedDuration() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_duration',
    problemMessage:
        'Avoid hardcoded Duration values in presentation code. '
        'Use DesignConstants.animation* or FieldGuideMotion.of(context).* tokens.',
    correctionMessage:
        'Replace Duration(milliseconds: 300) with '
        'DesignConstants.animationNormal or FieldGuideMotion.of(context).normal.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path.replaceAll('\\', '/');
    // WHY: Only presentation layer — data/domain layers may use Duration legitimately
    if (!filePath.contains('/presentation/')) return;
    if (filePath.contains('/test/') || filePath.contains('/integration_test/')) return;
    if (filePath.contains('/core/design_system/')) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName == 'Duration') {
        // WHY: Only flag Duration() with numeric literal arguments.
        // Duration(milliseconds: animationFast.inMilliseconds) is fine.
        for (final arg in node.argumentList.arguments) {
          final expr = arg is NamedExpression ? arg.expression : arg;
          if (expr is IntegerLiteral || expr is DoubleLiteral) {
            reporter.atNode(node.constructorName, _code);
            return;
          }
        }
      }
    });
  }
}
```

**IMPORTANT**: The implementing agent must add `import 'package:analyzer/dart/ast/ast.dart' show NamedExpression, IntegerLiteral, DoubleLiteral;` at the top.

---

### Sub-phase 0.9: Create `no_raw_navigator` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_navigator.dart`

**Agent**: `code-fixer-agent`

#### Step 0.9.1: Create `no_raw_navigator.dart`

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/no_raw_navigator.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A32: Flags raw Navigator.push/pop usage in presentation files.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "no raw navigator"
/// Use GoRouter (context.go/context.push) instead of Navigator.push/pop.
/// Severity: INFO (advisory, not blocking — some edge cases need Navigator)
class NoRawNavigator extends DartLintRule {
  NoRawNavigator() : super(code: _code);

  static const _code = LintCode(
    name: 'no_raw_navigator',
    // NOTE: INFO severity, not WARNING — this is advisory because some
    // patterns (e.g., closing dialogs) legitimately use Navigator.pop
    problemMessage:
        'Prefer GoRouter (context.go/context.push) over raw Navigator '
        'for route-level navigation. Navigator.pop is acceptable for '
        'dialogs and bottom sheets.',
    correctionMessage:
        'Replace Navigator.push/pushNamed with context.push/context.go '
        'from GoRouter.',
    errorSeverity: ErrorSeverity.INFO,
  );

  // WHY: These Navigator methods indicate route-level navigation that
  // should use GoRouter instead. We intentionally exclude pop/maybePop
  // since those are used for dialog/sheet dismissal.
  static const _bannedMethods = {
    'push',
    'pushNamed',
    'pushReplacement',
    'pushReplacementNamed',
    'pushAndRemoveUntil',
    'pushNamedAndRemoveUntil',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.path.replaceAll('\\', '/');
    if (!filePath.contains('/presentation/')) return;
    if (filePath.contains('/test/') || filePath.contains('/integration_test/')) return;
    if (filePath.contains('/core/design_system/')) return;
    // WHY: Router files legitimately use Navigator for transition builders
    if (filePath.contains('/core/router/')) return;

    context.registry.addMethodInvocation((node) {
      final target = node.realTarget;
      if (target == null) return;
      // NOTE: Matches Navigator.push(...), Navigator.of(context).push(...)
      // For Navigator.push static calls, target is SimpleIdentifier 'Navigator'
      final targetName = target is SimpleIdentifier ? target.name : '';
      if (targetName == 'Navigator' && _bannedMethods.contains(node.methodName.name)) {
        reporter.atNode(node.methodName, _code);
      }
    });
  }
}
```

**IMPORTANT**: The implementing agent must add `import 'package:analyzer/dart/ast/ast.dart' show SimpleIdentifier;` at the top.

---

### Sub-phase 0.10: Create `prefer_design_system_banner` lint rule

**Files:**
- Create: `fg_lint_packages/field_guide_lints/lib/architecture/rules/prefer_design_system_banner.dart`

**Agent**: `code-fixer-agent`

#### Step 0.10.1: Create `prefer_design_system_banner.dart`

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/rules/prefer_design_system_banner.dart
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A33: Flags feature-specific banner widgets that should compose AppBanner.
///
/// FROM SPEC: Design System Overhaul Phase 0 - "prefer design system banner"
/// Banner-like widgets (MaterialBanner, custom banner patterns) should compose
/// AppBanner or AppInfoBanner from the design system.
/// Severity: WARNING
class PreferDesignSystemBanner extends DartLintRule {
  PreferDesignSystemBanner() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_design_system_banner',
    problemMessage:
        'Avoid using raw MaterialBanner. Use AppInfoBanner or AppBanner '
        'from the design system for consistent banner styling.',
    correctionMessage:
        'Replace MaterialBanner() with AppInfoBanner() or compose from '
        'AppBanner for feature-specific banners.',
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
    if (filePath.contains('/core/design_system/')) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName == 'MaterialBanner') {
        reporter.atNode(node.constructorName, _code);
      }
    });

    // WHY: Also catch showMaterialBanner method calls
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'showMaterialBanner') {
        reporter.atNode(node.methodName, _code);
      }
    });
  }
}
```

---

### Sub-phase 0.11: Register all new rules in `architecture_rules.dart`

**Files:**
- Modify: `fg_lint_packages/field_guide_lints/lib/architecture/architecture_rules.dart`

**Agent**: `code-fixer-agent`

#### Step 0.11.1: Update `architecture_rules.dart` with new imports and rule registrations

Add imports for all 9 new rule files (the 10th rule is the extended `no_direct_snackbar` which already exists) and add their instances to the `architectureRules` list.

```dart
// File: fg_lint_packages/field_guide_lints/lib/architecture/architecture_rules.dart
//
// ADD these imports after the existing import block (after line 24):
import 'rules/no_raw_button.dart';
import 'rules/no_raw_divider.dart';
import 'rules/no_raw_tooltip.dart';
import 'rules/no_raw_dropdown.dart';
import 'rules/no_hardcoded_spacing.dart';
import 'rules/no_hardcoded_radius.dart';
import 'rules/no_hardcoded_duration.dart';
import 'rules/no_raw_navigator.dart';
import 'rules/prefer_design_system_banner.dart';

// ADD these entries to the architectureRules list (after NoRawTextField() on line 50):
//   NoRawButton(),
//   NoRawDivider(),
//   NoRawTooltip(),
//   NoRawDropdown(),
//   NoHardcodedSpacing(),
//   NoHardcodedRadius(),
//   NoHardcodedDuration(),
//   NoRawNavigator(),
//   PreferDesignSystemBanner(),
```

The final file should look like:

```dart
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'rules/avoid_supabase_singleton.dart';
import 'rules/no_direct_database_construction.dart';
import 'rules/no_raw_sql_in_presentation.dart';
import 'rules/no_raw_sql_in_di.dart';
import 'rules/no_datasource_import_in_presentation.dart';
import 'rules/no_business_logic_in_di.dart';
import 'rules/single_composition_root.dart';
import 'rules/no_service_construction_in_widgets.dart';
import 'rules/no_silent_catch.dart';
import 'rules/max_file_length.dart';
import 'rules/max_import_count.dart';
import 'rules/no_deprecated_app_theme.dart';
import 'rules/no_hardcoded_colors.dart';
import 'rules/no_hardcoded_form_type.dart';
import 'rules/no_duplicate_service_instances.dart';
import 'rules/no_async_lifecycle_without_await.dart';
import 'rules/no_raw_alert_dialog.dart';
import 'rules/no_raw_show_dialog.dart';
import 'rules/no_raw_bottom_sheet.dart';
import 'rules/no_raw_scaffold.dart';
import 'rules/no_direct_snackbar.dart';
import 'rules/no_inline_text_style.dart';
import 'rules/no_raw_text_field.dart';
// FROM SPEC: Design System Overhaul Phase 0 — 9 new lint rules
import 'rules/no_raw_button.dart';
import 'rules/no_raw_divider.dart';
import 'rules/no_raw_tooltip.dart';
import 'rules/no_raw_dropdown.dart';
import 'rules/no_hardcoded_spacing.dart';
import 'rules/no_hardcoded_radius.dart';
import 'rules/no_hardcoded_duration.dart';
import 'rules/no_raw_navigator.dart';
import 'rules/prefer_design_system_banner.dart';

/// All architecture lint rules (A1-A15, A17-A33). A16 is a built-in lint.
final List<LintRule> architectureRules = [
  AvoidSupabaseSingleton(),
  NoDirectDatabaseConstruction(),
  NoRawSqlInPresentation(),
  NoRawSqlInDi(),
  NoDatasourceImportInPresentation(),
  NoBusinessLogicInDi(),
  SingleCompositionRoot(),
  NoServiceConstructionInWidgets(),
  NoSilentCatch(),
  MaxFileLength(),
  MaxImportCount(),
  NoDeprecatedAppTheme(),
  NoHardcodedColors(),
  NoHardcodedFormType(),
  NoDuplicateServiceInstances(),
  NoAsyncLifecycleWithoutAwait(),
  NoRawAlertDialog(),
  NoRawShowDialog(),
  NoRawBottomSheet(),
  NoRawScaffold(),
  NoDirectSnackbar(),
  NoInlineTextStyle(),
  NoRawTextField(),
  // FROM SPEC: Design System Overhaul Phase 0 — new rules
  NoRawButton(),
  NoRawDivider(),
  NoRawTooltip(),
  NoRawDropdown(),
  NoHardcodedSpacing(),
  NoHardcodedRadius(),
  NoHardcodedDuration(),
  NoRawNavigator(),
  PreferDesignSystemBanner(),
];
```

---

### Sub-phase 0.12: Verify lint rules compile and analyze

**Files:** (no new files)

**Agent**: `code-fixer-agent`

#### Step 0.12.1: Run analyzer on lint package

```
pwsh -Command "cd fg_lint_packages/field_guide_lints && flutter analyze"
```

**Expected**: Zero errors. Warnings about unused imports are acceptable at this stage (the rules reference types like `NamedExpression` that need analyzer imports).

#### Step 0.12.2: Run analyzer on main project to capture violation inventory

```
pwsh -Command "flutter analyze 2>&1 | Select-String 'no_raw_button|no_raw_divider|no_raw_tooltip|no_raw_dropdown|no_hardcoded_spacing|no_hardcoded_radius|no_hardcoded_duration|no_raw_navigator|prefer_design_system_banner'"
```

**Expected**: A list of new warnings from the custom lint rules. This is the baseline violation inventory. The count does NOT need to be zero -- these are intentional warnings that will be resolved in later phases as components are migrated to the design system.

**NOTE**: If `flutter analyze` does not surface custom_lint rules, the implementing agent should use `pwsh -Command "dart run custom_lint"` from the project root instead.

---

## Phase 1: Tokens + Theme + HC Removal + Folder Structure

### Sub-phase 1.1: Create design system folder structure with barrel files

**Files:**
- Create: `lib/core/design_system/tokens/tokens.dart`
- Create: `lib/core/design_system/atoms/atoms.dart`
- Create: `lib/core/design_system/molecules/molecules.dart`
- Create: `lib/core/design_system/organisms/organisms.dart`
- Create: `lib/core/design_system/surfaces/surfaces.dart`
- Create: `lib/core/design_system/feedback/feedback.dart`
- Create: `lib/core/design_system/layout/layout.dart`
- Create: `lib/core/design_system/animation/animation.dart`

**Agent**: `code-fixer-agent`

#### Step 1.1.1: Create `tokens/tokens.dart` barrel

```dart
// File: lib/core/design_system/tokens/tokens.dart
// WHY: Sub-barrel for design token files. Re-exported by main design_system.dart barrel.
// New ThemeExtension files and moved token files will be exported here.

// NOTE: Exports will be added as files are moved/created in subsequent steps.
// Placeholder barrel to establish directory structure.
```

#### Step 1.1.2: Create `atoms/atoms.dart` barrel

```dart
// File: lib/core/design_system/atoms/atoms.dart
// WHY: Sub-barrel for atomic components (text, chip, toggle, icon, counter, progress).
// These are the smallest, most reusable building blocks.

// NOTE: Exports will be populated when components are moved from flat structure
// in Phase 2. This establishes the directory for future use.
```

#### Step 1.1.3: Create `molecules/molecules.dart` barrel

```dart
// File: lib/core/design_system/molecules/molecules.dart
// WHY: Sub-barrel for molecule components (search bar, list tile, section header).
// Molecules compose multiple atoms into reusable patterns.

// NOTE: Exports will be populated in Phase 2.
```

#### Step 1.1.4: Create `organisms/organisms.dart` barrel

```dart
// File: lib/core/design_system/organisms/organisms.dart
// WHY: Sub-barrel for organism components (section card, photo grid, form sections).
// Organisms are complex components composed of molecules and atoms.

// NOTE: Exports will be populated in Phase 2.
```

#### Step 1.1.5: Create `surfaces/surfaces.dart` barrel

```dart
// File: lib/core/design_system/surfaces/surfaces.dart
// WHY: Sub-barrel for surface/container components (scaffold, bottom sheet, dialog, glass card).
// Surfaces define layout boundaries and visual containers.

// NOTE: Exports will be populated in Phase 2.
```

#### Step 1.1.6: Create `feedback/feedback.dart` barrel

```dart
// File: lib/core/design_system/feedback/feedback.dart
// WHY: Sub-barrel for feedback components (snackbar, banners, empty/error/loading states).
// Feedback components communicate system state to users.

// NOTE: Exports will be populated in Phase 2+.
```

#### Step 1.1.7: Create `layout/layout.dart` barrel

```dart
// File: lib/core/design_system/layout/layout.dart
// WHY: Sub-barrel for responsive layout components (breakpoints, adaptive layouts, grids).
// Layout components handle responsive behavior across screen sizes.

// NOTE: Exports will be populated in Phase 3.
```

#### Step 1.1.8: Create `animation/animation.dart` barrel

```dart
// File: lib/core/design_system/animation/animation.dart
// WHY: Sub-barrel for animation utilities (staggered list, fade-in, transitions).
// Animation components provide consistent motion patterns.

// NOTE: Exports will be populated in Phase 4.
```

---

### Sub-phase 1.2: Move token files to `tokens/` directory

**Files:**
- Move: `lib/core/theme/colors.dart` -> `lib/core/design_system/tokens/app_colors.dart`
- Move: `lib/core/theme/design_constants.dart` -> `lib/core/design_system/tokens/design_constants.dart`
- Move: `lib/core/theme/field_guide_colors.dart` -> `lib/core/design_system/tokens/field_guide_colors.dart`
- Modify: `lib/core/design_system/tokens/tokens.dart`
- Modify: `lib/core/theme/theme.dart` (keep as re-export shim for backward compatibility)
- Modify: `lib/core/theme/app_theme.dart` (update imports)

**Agent**: `code-fixer-agent`

#### Step 1.2.1: Copy `colors.dart` to `tokens/app_colors.dart`

Create `lib/core/design_system/tokens/app_colors.dart` with the exact contents of `lib/core/theme/colors.dart`. Do NOT delete the original yet.

The file content is identical to the current `lib/core/theme/colors.dart` (218 lines). No changes to the class itself at this step.

#### Step 1.2.2: Copy `design_constants.dart` to `tokens/design_constants.dart`

Create `lib/core/design_system/tokens/design_constants.dart` with the exact contents of `lib/core/theme/design_constants.dart` (97 lines). Update the import at line 1:

```dart
// File: lib/core/design_system/tokens/design_constants.dart
import 'package:flutter/material.dart';
// NOTE: No other import changes needed — DesignConstants has no internal deps
```

#### Step 1.2.3: Copy `field_guide_colors.dart` to `tokens/field_guide_colors.dart`

Create `lib/core/design_system/tokens/field_guide_colors.dart` with the contents of `lib/core/theme/field_guide_colors.dart` (220 lines). Update the import on line 2:

```dart
// File: lib/core/design_system/tokens/field_guide_colors.dart
import 'package:flutter/material.dart';
import 'app_colors.dart'; // WHY: Changed from 'colors.dart' — now co-located in tokens/
```

#### Step 1.2.4: Update `tokens/tokens.dart` barrel

```dart
// File: lib/core/design_system/tokens/tokens.dart
// WHY: Sub-barrel for all design token files.
// These are re-exported by the main design_system.dart barrel.

export 'app_colors.dart';
export 'design_constants.dart';
export 'field_guide_colors.dart';
// NOTE: New ThemeExtension files (spacing, radii, motion, shadows) will be added
// in sub-phase 1.6 after they are created.
```

#### Step 1.2.5: Update `lib/core/theme/theme.dart` to re-export from new locations

```dart
// File: lib/core/theme/theme.dart
// WHY: Backward-compatibility shim. Keeps existing imports working during migration.
// NOTE: Once all consumers are updated, this file can be deleted.
export 'app_theme.dart';
export '../design_system/tokens/app_colors.dart';
export '../design_system/tokens/design_constants.dart';
export '../design_system/tokens/field_guide_colors.dart';
```

#### Step 1.2.6: Replace old files with re-export shims

Replace `lib/core/theme/colors.dart` with:

```dart
// File: lib/core/theme/colors.dart
// WHY: Re-export shim — actual file moved to design_system/tokens/app_colors.dart
// NOTE: This shim will be deleted once all direct importers are updated.
export '../design_system/tokens/app_colors.dart';
```

Replace `lib/core/theme/design_constants.dart` with:

```dart
// File: lib/core/theme/design_constants.dart
// WHY: Re-export shim — actual file moved to design_system/tokens/design_constants.dart
export '../design_system/tokens/design_constants.dart';
```

Replace `lib/core/theme/field_guide_colors.dart` with:

```dart
// File: lib/core/theme/field_guide_colors.dart
// WHY: Re-export shim — actual file moved to design_system/tokens/field_guide_colors.dart
export '../design_system/tokens/field_guide_colors.dart';
```

#### Step 1.2.7: Update `app_theme.dart` imports

In `lib/core/theme/app_theme.dart`, update lines 3-5:

```dart
// FROM:
// import 'colors.dart';
// import 'design_constants.dart';
// import 'field_guide_colors.dart';

// TO:
import 'package:construction_inspector/core/design_system/tokens/app_colors.dart';
import 'package:construction_inspector/core/design_system/tokens/design_constants.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_colors.dart';
```

// WHY: Direct imports to canonical location. The re-export shims in lib/core/theme/ are for external consumers only.

#### Step 1.2.8: Verify with analyzer

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors. The re-export shims ensure all existing imports continue working. Warnings from Phase 0 lint rules are expected and acceptable.

---

### Sub-phase 1.3: Delete HC theme from `AppColors`

**Files:**
- Modify: `lib/core/design_system/tokens/app_colors.dart` (lines 84-101 — delete 13 `hc*` constants)

**Agent**: `code-fixer-agent`

#### Step 1.3.1: Remove all `hc*` constants from `AppColors`

In `lib/core/design_system/tokens/app_colors.dart`, delete the entire "HIGH CONTRAST THEME - COLORS" section (lines 84-101 in original, which includes the section comment and all 13 constants):

Delete these lines:
```
  // ==========================================================================
  // HIGH CONTRAST THEME - COLORS
  // ==========================================================================

  static const Color hcBackground = Color(0xFF000000);
  static const Color hcSurface = Color(0xFF121212);
  static const Color hcSurfaceElevated = Color(0xFF1E1E1E);
  static const Color hcBorder = Color(0xFFFFFFFF);
  static const Color hcPrimary = Color(0xFF00FFFF);
  static const Color hcAccent = Color(0xFFFFFF00);
  static const Color hcSuccess = Color(0xFF00FF00);
  static const Color hcError = Color(0xFFFF0000);
  static const Color hcWarning = Color(0xFFFFAA00);
  static const Color hcTextPrimary = Color(0xFFFFFFFF);
  static const Color hcTextSecondary = Color(0xFFCCCCCC);

  // Disabled / inactive states (HC theme)
  static const Color hcDisabledBackground = Color(0xFF333333);
  static const Color hcDisabledForeground = Color(0xFF666666);
```

---

### Sub-phase 1.4: Delete HC theme from `FieldGuideColors`

**Files:**
- Modify: `lib/core/design_system/tokens/field_guide_colors.dart` (delete `highContrast` const instance, lines 123-140 in original)

**Agent**: `code-fixer-agent`

#### Step 1.4.1: Remove `highContrast` instance from `FieldGuideColors`

In `lib/core/design_system/tokens/field_guide_colors.dart`, delete the entire `static const highContrast = FieldGuideColors(...)` block (originally lines 123-140):

Delete this block:
```
  static const highContrast = FieldGuideColors(
    surfaceElevated: AppColors.hcSurfaceElevated,
    surfaceGlass: Color(0xCC121212),
    surfaceBright: Color(0xFF333333),
    textTertiary: Color(0xFF808080),
    textInverse: Color(0xFF000000),
    statusSuccess: AppColors.hcSuccess,
    statusWarning: AppColors.hcWarning,
    statusInfo: AppColors.hcPrimary,
    warningBackground: Color(0x1AFFAA00),
    warningBorder: Color(0x33FFAA00),
    shadowLight: Colors.transparent,
    gradientStart: AppColors.hcPrimary,
    gradientEnd: AppColors.hcPrimary,
    accentAmber: AppColors.hcAccent,
    accentOrange: AppColors.hcWarning,
    dragHandleColor: Color(0xFFFFFFFF),
  );
```

---

### Sub-phase 1.5: Delete HC theme from `AppTheme` and `ThemeProvider`

**Files:**
- Modify: `lib/core/theme/app_theme.dart` (delete `highContrastTheme` getter ~500 lines, delete HC re-exports ~15 lines)
- Modify: `lib/features/settings/presentation/providers/theme_provider.dart` (remove `highContrast` enum, `isHighContrast`, `setHighContrast`)
- Modify: `lib/features/settings/presentation/widgets/theme_section.dart` (remove HC radio option)

**Agent**: `code-fixer-agent`

#### Step 1.5.1: Remove `highContrastTheme` getter from `AppTheme`

In `lib/core/theme/app_theme.dart`:

1. Delete the entire `highContrastTheme` getter (lines 1265-1777 approximately). This is the block starting with:
   ```
   // ==========================================================================
   // HIGH CONTRAST THEME
   // ==========================================================================
   static ThemeData get highContrastTheme {
   ```
   All the way to its closing `}`.

2. Delete the HC color re-exports at the top of the class (lines 67-83 approximately):
   ```
   // High contrast theme
   static const Color hcBackground = AppColors.hcBackground;
   static const Color hcSurface = AppColors.hcSurface;
   static const Color hcSurfaceElevated = AppColors.hcSurfaceElevated;
   static const Color hcBorder = AppColors.hcBorder;
   static const Color hcPrimary = AppColors.hcPrimary;
   static const Color hcAccent = AppColors.hcAccent;
   static const Color hcError = AppColors.hcError;
   static const Color hcWarning = AppColors.hcWarning;
   static const Color hcTextPrimary = AppColors.hcTextPrimary;
   static const Color hcTextSecondary = AppColors.hcTextSecondary;
   static const Color hcDisabledBackground = AppColors.hcDisabledBackground;
   static const Color hcDisabledForeground = AppColors.hcDisabledForeground;
   static const Color hcSuccess = AppColors.hcSuccess;
   ```

#### Step 1.5.2: Update `ThemeProvider` — remove HC enum value and methods

Rewrite `lib/features/settings/presentation/providers/theme_provider.dart`:

```dart
// File: lib/features/settings/presentation/providers/theme_provider.dart
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:construction_inspector/core/logging/logger.dart';
import 'package:construction_inspector/core/theme/app_theme.dart';

/// FROM SPEC: Design System Overhaul Phase 1 — 2-theme system (dark + light only).
/// HC theme removed per spec Section 9.
enum AppThemeMode {
  light,
  dark,
  // NOTE: highContrast removed. Old persisted 'highContrast' values safely
  // fall back to dark via the .where().firstOrNull pattern in _loadTheme().
}

/// Theme mode provider for managing app-wide theme state.
///
/// Supports 2 themes: Light and Dark (default).
/// Persists theme preference to SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  AppThemeMode _themeMode = AppThemeMode.dark; // WHY: Dark is default for field use
  bool _isLoading = true;

  ThemeProvider() {
    unawaited(_loadTheme());
  }

  /// Current app theme mode.
  AppThemeMode get themeMode => _themeMode;

  /// Whether theme is loading from preferences.
  bool get isLoading => _isLoading;

  /// Whether dark mode is active.
  bool get isDark => _themeMode == AppThemeMode.dark;

  /// Whether light mode is active.
  bool get isLight => _themeMode == AppThemeMode.light;

  /// Get the current ThemeData based on selected mode.
  ThemeData get currentTheme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
    }
  }

  /// Get theme display name for UI.
  String get themeName {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  /// Load theme from SharedPreferences.
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeKey);

      if (savedMode != null) {
        // NOTE: Safe enum deserialization — defaults to dark if saved value is
        // unrecognized (handles old 'highContrast' gracefully)
        _themeMode = AppThemeMode.values
                .where((mode) => mode.name == savedMode)
                .firstOrNull ??
            AppThemeMode.dark;
      }
    } on Exception catch (e) {
      Logger.ui('[ThemeProvider] loadTheme error: $e');
      _themeMode = AppThemeMode.dark;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set theme mode and persist.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } on Exception catch (e) {
      Logger.ui('[ThemeProvider] theme persistence error: $e');
    }
  }

  /// Cycle to the next theme mode.
  Future<void> cycleTheme() async {
    final nextIndex = (_themeMode.index + 1) % AppThemeMode.values.length;
    await setThemeMode(AppThemeMode.values[nextIndex]);
  }

  /// Set to dark mode.
  Future<void> setDark() => setThemeMode(AppThemeMode.dark);

  /// Set to light mode.
  Future<void> setLight() => setThemeMode(AppThemeMode.light);
}
```

#### Step 1.5.3: Update `ThemeSection` — remove HC radio option

```dart
// File: lib/features/settings/presentation/widgets/theme_section.dart
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:construction_inspector/shared/shared.dart';
import '../providers/theme_provider.dart';

class ThemeSection extends StatelessWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return RadioGroup<AppThemeMode>(
          key: TestingKeys.settingsThemeDropdown,
          groupValue: themeProvider.themeMode,
          onChanged: (value) {
            if (value != null) unawaited(themeProvider.setThemeMode(value));
          },
          // FROM SPEC: Phase 1 HC removal — only 2 theme options now
          child: const Column(
            children: [
              RadioListTile<AppThemeMode>(
                key: TestingKeys.settingsThemeDark,
                secondary: Icon(Icons.dark_mode),
                title: Text('Dark Mode'),
                value: AppThemeMode.dark,
              ),
              RadioListTile<AppThemeMode>(
                key: TestingKeys.settingsThemeLight,
                secondary: Icon(Icons.light_mode),
                title: Text('Light Mode'),
                value: AppThemeMode.light,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

#### Step 1.5.4: Verify HC removal compiles

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors. If there are errors from references to `AppColors.hc*` or `FieldGuideColors.highContrast` or `AppTheme.highContrastTheme` or `AppThemeMode.highContrast` in other files, those must be fixed before continuing. The blast-radius shows 3 lib files reference `AppTheme.highContrastTheme` — `budget_overview_card.dart` and `project_dashboard_screen.dart` do NOT reference HC directly (only `theme_provider.dart` does via `currentTheme` switch). Any remaining references should be removed.

---

### Sub-phase 1.6: HC test cleanup

**Files:**
- Delete: `test/golden/themes/high_contrast_theme_test.dart`
- Modify: `test/golden/test_helpers.dart` (remove HC from `testWidgetInAllThemes`)
- Modify: `test/core/theme/field_guide_colors_test.dart` (remove HC test cases)
- Modify: `test/golden/components/dashboard_widgets_test.dart` (remove HC variant)
- Modify: `test/golden/components/form_fields_test.dart` (remove HC variant)
- Modify: `test/golden/components/quantity_cards_test.dart` (remove HC variant)
- Modify: `test/golden/states/empty_state_test.dart` (remove HC variant)
- Modify: `test/golden/states/error_state_test.dart` (remove HC variant)
- Modify: `test/golden/states/loading_state_test.dart` (remove HC variant)
- Modify: `test/golden/widgets/confirmation_dialog_test.dart` (remove HC variant)
- Modify: `test/golden/widgets/entry_card_test.dart` (remove HC variant)
- Modify: `test/golden/widgets/project_card_test.dart` (remove HC variant)

**Agent**: `qa-testing-agent`

#### Step 1.6.1: Delete `high_contrast_theme_test.dart`

Delete the file `test/golden/themes/high_contrast_theme_test.dart` entirely.

#### Step 1.6.2: Update `test_helpers.dart` — remove HC from `testWidgetInAllThemes`

In `test/golden/test_helpers.dart`, update the `testWidgetInAllThemes` function (lines 86-121) to remove the HC test block:

```dart
/// Helper to test a widget against a golden file across both themes.
///
/// Creates separate golden files for dark and light themes.
/// FROM SPEC: HC theme removed in Design System Overhaul Phase 1.
Future<void> testWidgetInAllThemes(
  WidgetTester tester,
  Widget widget,
  String baseFileName, {
  Size? size,
}) async {
  // Test dark theme
  await pumpGoldenWidget(
    tester,
    goldenTestWrapper(widget, theme: AppTheme.darkTheme, size: size),
  );
  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('../goldens/${baseFileName}_dark.png'),
  );

  // Test light theme
  await pumpGoldenWidget(
    tester,
    goldenTestWrapper(widget, theme: AppTheme.lightTheme, size: size),
  );
  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('../goldens/${baseFileName}_light.png'),
  );
  // NOTE: High contrast block removed — HC theme deleted per spec Section 9
}
```

#### Step 1.6.3: Update `field_guide_colors_test.dart` — remove HC test cases

In `test/core/theme/field_guide_colors_test.dart`, remove all test cases that reference `FieldGuideColors.highContrast`. Specifically remove:

- `test('dark and highContrast surfaceGlass differ', ...)` (lines 16-20 approx)
- `test('light and highContrast textTertiary differ', ...)` (lines 22-27 approx)
- `test('HC shadowLight is transparent (no subtle shadows)', ...)` (lines 29-31 approx)
- `test('HC gradientStart equals gradientEnd (no gradient)', ...)` (lines 33-38 approx)

Keep the `test('dark and light surfaceElevated differ', ...)` test and all `of(context)` tests.

#### Step 1.6.4: Remove HC variants from all 9 golden test files

For each of these files, delete the `testWidgets` block that uses `AppTheme.highContrastTheme`:

1. `test/golden/components/dashboard_widgets_test.dart` — delete the `'renders in high contrast theme'` testWidgets block
2. `test/golden/components/form_fields_test.dart` — delete the HC testWidgets block
3. `test/golden/components/quantity_cards_test.dart` — delete the HC testWidgets block
4. `test/golden/states/empty_state_test.dart` — delete the HC testWidgets block
5. `test/golden/states/error_state_test.dart` — delete the HC testWidgets block
6. `test/golden/states/loading_state_test.dart` — delete the HC testWidgets block
7. `test/golden/widgets/confirmation_dialog_test.dart` — delete the HC testWidgets block
8. `test/golden/widgets/entry_card_test.dart` — delete the HC testWidgets block
9. `test/golden/widgets/project_card_test.dart` — delete the HC testWidgets block

Each deletion follows the same pattern: find the testWidgets call containing `AppTheme.highContrastTheme` and remove the entire test, including the `matchesGoldenFile('*_high_contrast.png')` expectation.

#### Step 1.6.5: Verify test cleanup compiles

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors. The `AppTheme.highContrastTheme` symbol no longer exists, so any remaining references will show as compile errors.

---

### Sub-phase 1.7: Create new ThemeExtension classes

**Files:**
- Create: `lib/core/design_system/tokens/field_guide_spacing.dart`
- Create: `lib/core/design_system/tokens/field_guide_radii.dart`
- Create: `lib/core/design_system/tokens/field_guide_motion.dart`
- Create: `lib/core/design_system/tokens/field_guide_shadows.dart`
- Modify: `lib/core/design_system/tokens/tokens.dart` (add exports)

**Agent**: `code-fixer-agent`

#### Step 1.7.1: Create `FieldGuideSpacing` ThemeExtension

```dart
// File: lib/core/design_system/tokens/field_guide_spacing.dart
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// FROM SPEC: Design System Overhaul Phase 1 — spacing token ThemeExtension.
///
/// WHY: Replaces hardcoded DesignConstants.space* references with context-aware
/// tokens. Follows the exact same pattern as FieldGuideColors (sentinel copyWith,
/// lerp, static of(context), const variant instances).
///
/// NOTE: Only the 6 primary spacing values are promoted to ThemeExtension fields.
/// Intermediate values (space3=12, space5=20, space10=40, space16=64) remain in
/// DesignConstants as static fallbacks — they are used infrequently and don't
/// need theme-variant behavior.
class FieldGuideSpacing extends ThemeExtension<FieldGuideSpacing> {
  const FieldGuideSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  /// 4.0 — tight padding, icon gaps, badge margins
  final double xs;

  /// 8.0 — standard internal padding, chip spacing
  final double sm;

  /// 16.0 — section padding, card content insets
  final double md;

  /// 24.0 — section gaps, form field spacing
  final double lg;

  /// 32.0 — large section separators, header spacing
  final double xl;

  /// 48.0 — page-level padding, major section breaks
  final double xxl;

  // ===========================================================================
  // VARIANT INSTANCES
  // ===========================================================================

  /// Standard spacing — used for both dark and light themes.
  /// WHY: Spacing does not vary by theme brightness — one instance suffices.
  static const standard = FieldGuideSpacing(
    xs: 4.0,   // FROM SPEC: maps to DesignConstants.space1
    sm: 8.0,   // FROM SPEC: maps to DesignConstants.space2
    md: 16.0,  // FROM SPEC: maps to DesignConstants.space4
    lg: 24.0,  // FROM SPEC: maps to DesignConstants.space6
    xl: 32.0,  // FROM SPEC: maps to DesignConstants.space8
    xxl: 48.0, // FROM SPEC: maps to DesignConstants.space12
  );

  // ===========================================================================
  // CONVENIENCE ACCESSOR
  // ===========================================================================

  /// WHY: Mirrors FieldGuideColors.of(context) pattern.
  /// Falls back to standard if extension is missing (defensive).
  static FieldGuideSpacing of(BuildContext context) {
    return Theme.of(context).extension<FieldGuideSpacing>() ?? standard;
  }

  // ===========================================================================
  // ThemeExtension OVERRIDES
  // ===========================================================================

  static const _sentinel = Object();

  @override
  FieldGuideSpacing copyWith({
    Object? xs = _sentinel,
    Object? sm = _sentinel,
    Object? md = _sentinel,
    Object? lg = _sentinel,
    Object? xl = _sentinel,
    Object? xxl = _sentinel,
  }) {
    return FieldGuideSpacing(
      xs: identical(xs, _sentinel) ? this.xs : xs! as double,
      sm: identical(sm, _sentinel) ? this.sm : sm! as double,
      md: identical(md, _sentinel) ? this.md : md! as double,
      lg: identical(lg, _sentinel) ? this.lg : lg! as double,
      xl: identical(xl, _sentinel) ? this.xl : xl! as double,
      xxl: identical(xxl, _sentinel) ? this.xxl : xxl! as double,
    );
  }

  @override
  FieldGuideSpacing lerp(FieldGuideSpacing? other, double t) {
    if (other is! FieldGuideSpacing) return this;
    return FieldGuideSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }
}
```

#### Step 1.7.2: Create `FieldGuideRadii` ThemeExtension

```dart
// File: lib/core/design_system/tokens/field_guide_radii.dart
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// FROM SPEC: Design System Overhaul Phase 1 — border radius token ThemeExtension.
///
/// WHY: Replaces hardcoded DesignConstants.radius* references with context-aware
/// tokens. Single variant (no density change per theme).
class FieldGuideRadii extends ThemeExtension<FieldGuideRadii> {
  const FieldGuideRadii({
    required this.xs,
    required this.sm,
    required this.compact,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  /// 4.0 — tight chips, badges, inline tags
  final double xs;

  /// 8.0 — standard cards, inputs, buttons
  final double sm;

  /// 10.0 — bottom sheets, action menus (between sm and md)
  final double compact;

  /// 12.0 — dialogs, section cards
  final double md;

  /// 16.0 — large cards, feature panels
  final double lg;

  /// 24.0 — bottom sheet tops, modal headers
  final double xl;

  /// 999.0 — fully round (pills, circular badges)
  final double full;

  // ===========================================================================
  // VARIANT INSTANCES
  // ===========================================================================

  /// Standard radii — used for both dark and light themes.
  /// WHY: Radii do not vary by theme brightness — one instance suffices.
  static const standard = FieldGuideRadii(
    xs: 4.0,     // FROM SPEC: maps to DesignConstants.radiusXSmall
    sm: 8.0,     // FROM SPEC: maps to DesignConstants.radiusSmall
    compact: 10.0, // FROM SPEC: maps to DesignConstants.radiusCompact
    md: 12.0,    // FROM SPEC: maps to DesignConstants.radiusMedium
    lg: 16.0,    // FROM SPEC: maps to DesignConstants.radiusLarge
    xl: 24.0,    // FROM SPEC: maps to DesignConstants.radiusXLarge
    full: 999.0, // FROM SPEC: maps to DesignConstants.radiusFull
  );

  // ===========================================================================
  // CONVENIENCE ACCESSOR
  // ===========================================================================

  static FieldGuideRadii of(BuildContext context) {
    return Theme.of(context).extension<FieldGuideRadii>() ?? standard;
  }

  // ===========================================================================
  // ThemeExtension OVERRIDES
  // ===========================================================================

  static const _sentinel = Object();

  @override
  FieldGuideRadii copyWith({
    Object? xs = _sentinel,
    Object? sm = _sentinel,
    Object? compact = _sentinel,
    Object? md = _sentinel,
    Object? lg = _sentinel,
    Object? xl = _sentinel,
    Object? full = _sentinel,
  }) {
    return FieldGuideRadii(
      xs: identical(xs, _sentinel) ? this.xs : xs! as double,
      sm: identical(sm, _sentinel) ? this.sm : sm! as double,
      compact: identical(compact, _sentinel) ? this.compact : compact! as double,
      md: identical(md, _sentinel) ? this.md : md! as double,
      lg: identical(lg, _sentinel) ? this.lg : lg! as double,
      xl: identical(xl, _sentinel) ? this.xl : xl! as double,
      full: identical(full, _sentinel) ? this.full : full! as double,
    );
  }

  @override
  FieldGuideRadii lerp(FieldGuideRadii? other, double t) {
    if (other is! FieldGuideRadii) return this;
    return FieldGuideRadii(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      compact: lerpDouble(compact, other.compact, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      full: lerpDouble(full, other.full, t)!,
    );
  }
}
```

#### Step 1.7.3: Create `FieldGuideMotion` ThemeExtension

```dart
// File: lib/core/design_system/tokens/field_guide_motion.dart
import 'package:flutter/material.dart';

/// FROM SPEC: Design System Overhaul Phase 1 — animation/motion token ThemeExtension.
///
/// WHY: Replaces hardcoded DesignConstants.animation* and curve* references.
/// Provides a `reduced` variant for accessibility (reduce-motion preference).
///
/// NOTE: Duration and Curve types cannot be lerped in a meaningful way,
/// so lerp() returns `other` directly when t >= 0.5, else `this`.
class FieldGuideMotion extends ThemeExtension<FieldGuideMotion> {
  const FieldGuideMotion({
    required this.fast,
    required this.normal,
    required this.slow,
    required this.pageTransition,
    required this.curveStandard,
    required this.curveDecelerate,
    required this.curveAccelerate,
    required this.curveBounce,
    required this.curveSpring,
  });

  /// 150ms — micro-interactions, hover states, icon transitions
  final Duration fast;

  /// 300ms — standard transitions, expand/collapse
  final Duration normal;

  /// 500ms — large transitions, page-level animations
  final Duration slow;

  /// 350ms — page transition duration
  final Duration pageTransition;

  /// Curves.easeInOutCubic — standard motion curve
  final Curve curveStandard;

  /// Curves.easeOut — deceleration curve for entering elements
  final Curve curveDecelerate;

  /// Curves.easeIn — acceleration curve for exiting elements
  final Curve curveAccelerate;

  /// Curves.elasticOut — bounce effect for attention-grabbing
  final Curve curveBounce;

  /// Curves.easeOutBack — spring overshoot for playful transitions
  final Curve curveSpring;

  // ===========================================================================
  // VARIANT INSTANCES
  // ===========================================================================

  /// Standard motion — default durations and curves.
  static const standard = FieldGuideMotion(
    fast: Duration(milliseconds: 150),           // FROM SPEC: DesignConstants.animationFast
    normal: Duration(milliseconds: 300),         // FROM SPEC: DesignConstants.animationNormal
    slow: Duration(milliseconds: 500),           // FROM SPEC: DesignConstants.animationSlow
    pageTransition: Duration(milliseconds: 350), // FROM SPEC: DesignConstants.animationPageTransition
    curveStandard: Curves.easeInOutCubic,        // FROM SPEC: DesignConstants.curveDefault
    curveDecelerate: Curves.easeOut,             // FROM SPEC: DesignConstants.curveDecelerate
    curveAccelerate: Curves.easeIn,              // FROM SPEC: DesignConstants.curveAccelerate
    curveBounce: Curves.elasticOut,              // FROM SPEC: DesignConstants.curveBounce
    curveSpring: Curves.easeOutBack,             // FROM SPEC: DesignConstants.curveSpring
  );

  /// Reduced motion — for accessibility (prefers-reduced-motion).
  /// WHY: All durations are zero, curves are linear. This ensures
  /// animations complete instantly for users who prefer reduced motion.
  static const reduced = FieldGuideMotion(
    fast: Duration.zero,
    normal: Duration.zero,
    slow: Duration.zero,
    pageTransition: Duration.zero,
    curveStandard: Curves.linear,
    curveDecelerate: Curves.linear,
    curveAccelerate: Curves.linear,
    curveBounce: Curves.linear,
    curveSpring: Curves.linear,
  );

  // ===========================================================================
  // CONVENIENCE ACCESSOR
  // ===========================================================================

  static FieldGuideMotion of(BuildContext context) {
    return Theme.of(context).extension<FieldGuideMotion>() ?? standard;
  }

  // ===========================================================================
  // ThemeExtension OVERRIDES
  // ===========================================================================

  static const _sentinel = Object();

  @override
  FieldGuideMotion copyWith({
    Object? fast = _sentinel,
    Object? normal = _sentinel,
    Object? slow = _sentinel,
    Object? pageTransition = _sentinel,
    Object? curveStandard = _sentinel,
    Object? curveDecelerate = _sentinel,
    Object? curveAccelerate = _sentinel,
    Object? curveBounce = _sentinel,
    Object? curveSpring = _sentinel,
  }) {
    return FieldGuideMotion(
      fast: identical(fast, _sentinel) ? this.fast : fast! as Duration,
      normal: identical(normal, _sentinel) ? this.normal : normal! as Duration,
      slow: identical(slow, _sentinel) ? this.slow : slow! as Duration,
      pageTransition: identical(pageTransition, _sentinel) ? this.pageTransition : pageTransition! as Duration,
      curveStandard: identical(curveStandard, _sentinel) ? this.curveStandard : curveStandard! as Curve,
      curveDecelerate: identical(curveDecelerate, _sentinel) ? this.curveDecelerate : curveDecelerate! as Curve,
      curveAccelerate: identical(curveAccelerate, _sentinel) ? this.curveAccelerate : curveAccelerate! as Curve,
      curveBounce: identical(curveBounce, _sentinel) ? this.curveBounce : curveBounce! as Curve,
      curveSpring: identical(curveSpring, _sentinel) ? this.curveSpring : curveSpring! as Curve,
    );
  }

  @override
  FieldGuideMotion lerp(FieldGuideMotion? other, double t) {
    // NOTE: Duration and Curve cannot be meaningfully interpolated.
    // Use snap behavior: return other when t >= 0.5, else this.
    if (other is! FieldGuideMotion) return this;
    return t < 0.5 ? this : other;
  }
}
```

#### Step 1.7.4: Create `FieldGuideShadows` ThemeExtension

```dart
// File: lib/core/design_system/tokens/field_guide_shadows.dart
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// FROM SPEC: Design System Overhaul Phase 1 — elevation/shadow token ThemeExtension.
///
/// WHY: Replaces hardcoded DesignConstants.elevation* references with context-aware
/// shadow tokens. Provides a `flat` variant (no shadows) for accessibility or
/// reduced visual complexity preferences.
///
/// NOTE: Uses double elevation values rather than List<BoxShadow> for simplicity.
/// Components apply shadows via Material elevation or BoxDecoration with these values.
class FieldGuideShadows extends ThemeExtension<FieldGuideShadows> {
  const FieldGuideShadows({
    required this.low,
    required this.medium,
    required this.high,
    required this.modal,
  });

  /// 2.0 — subtle lift for cards, list tiles
  final double low;

  /// 4.0 — standard elevation for FABs, nav bars
  final double medium;

  /// 8.0 — prominent elevation for popovers, menus
  final double high;

  /// 16.0 — maximum elevation for dialogs, modals
  final double modal;

  // ===========================================================================
  // VARIANT INSTANCES
  // ===========================================================================

  /// Standard shadows — default elevation values.
  static const standard = FieldGuideShadows(
    low: 2.0,    // FROM SPEC: DesignConstants.elevationLow
    medium: 4.0, // FROM SPEC: DesignConstants.elevationMedium
    high: 8.0,   // FROM SPEC: DesignConstants.elevationHigh
    modal: 16.0, // FROM SPEC: DesignConstants.elevationModal
  );

  /// Flat — no shadows. WHY: For accessibility or high-contrast-like modes
  /// where shadows add visual noise without communicating depth.
  static const flat = FieldGuideShadows(
    low: 0.0,
    medium: 0.0,
    high: 0.0,
    modal: 0.0,
  );

  // ===========================================================================
  // CONVENIENCE ACCESSOR
  // ===========================================================================

  static FieldGuideShadows of(BuildContext context) {
    return Theme.of(context).extension<FieldGuideShadows>() ?? standard;
  }

  // ===========================================================================
  // ThemeExtension OVERRIDES
  // ===========================================================================

  static const _sentinel = Object();

  @override
  FieldGuideShadows copyWith({
    Object? low = _sentinel,
    Object? medium = _sentinel,
    Object? high = _sentinel,
    Object? modal = _sentinel,
  }) {
    return FieldGuideShadows(
      low: identical(low, _sentinel) ? this.low : low! as double,
      medium: identical(medium, _sentinel) ? this.medium : medium! as double,
      high: identical(high, _sentinel) ? this.high : high! as double,
      modal: identical(modal, _sentinel) ? this.modal : modal! as double,
    );
  }

  @override
  FieldGuideShadows lerp(FieldGuideShadows? other, double t) {
    if (other is! FieldGuideShadows) return this;
    return FieldGuideShadows(
      low: lerpDouble(low, other.low, t)!,
      medium: lerpDouble(medium, other.medium, t)!,
      high: lerpDouble(high, other.high, t)!,
      modal: lerpDouble(modal, other.modal, t)!,
    );
  }
}
```

#### Step 1.7.5: Update `tokens/tokens.dart` barrel with new exports

```dart
// File: lib/core/design_system/tokens/tokens.dart
// WHY: Sub-barrel for all design token files.
// Re-exported by the main design_system.dart barrel.

export 'app_colors.dart';
export 'design_constants.dart';
export 'field_guide_colors.dart';
// FROM SPEC: New ThemeExtension token classes — Phase 1
export 'field_guide_spacing.dart';
export 'field_guide_radii.dart';
export 'field_guide_motion.dart';
export 'field_guide_shadows.dart';
```

#### Step 1.7.6: Verify new extensions compile

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors.

---

### Sub-phase 1.8: Theme collapse — data-driven `AppTheme.build()`

**Files:**
- Modify: `lib/core/theme/app_theme.dart` (major refactor: collapse to data-driven builder)

**Agent**: `code-fixer-agent`

#### Step 1.8.1: Refactor `AppTheme` to data-driven builder

This is the largest single step. The current `AppTheme` has ~1,265 lines (after HC deletion). Refactor to a `build()` method that accepts token parameters, with `darkTheme` and `lightTheme` as thin wrappers. Target: <400 lines total.

The implementing agent should:

1. Extract the `ColorScheme` for dark and light into private static const fields (`_darkColorScheme`, `_lightColorScheme`).

2. Create a `static ThemeData build({...})` method that takes `ColorScheme`, `FieldGuideColors`, `FieldGuideSpacing`, `FieldGuideRadii`, `FieldGuideMotion`, `FieldGuideShadows`, `Brightness`, and a scaffold background color. This method builds ALL component themes using the parameters instead of hardcoded values.

3. Convert `darkTheme` and `lightTheme` getters to delegate to `build()`.

4. Keep the deprecated re-exports section at the top UNCHANGED (those will be removed in a separate cleanup phase).

The complete `AppTheme` class structure should be:

```dart
// File: lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:construction_inspector/core/design_system/tokens/app_colors.dart';
import 'package:construction_inspector/core/design_system/tokens/design_constants.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_colors.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_spacing.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_radii.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_motion.dart';
import 'package:construction_inspector/core/design_system/tokens/field_guide_shadows.dart';

/// FROM SPEC: Design System Overhaul Phase 1 — data-driven theme builder.
/// WHY: Collapsed from 3 monolithic getters (~1,777 lines) to a single build()
/// method (~350 lines) that eliminates duplication across themes.
class AppTheme {
  // ==========================================================================
  // COLOR EXPORTS (for backwards compatibility — will be removed in Phase 6)
  // ==========================================================================

  // [KEEP ALL EXISTING DEPRECATED RE-EXPORTS UNCHANGED]
  // ... (the implementing agent should copy lines 14-168 from the current file,
  //      minus the HC re-exports which were deleted in step 1.5.1)

  // ==========================================================================
  // COLOR SCHEMES
  // ==========================================================================

  static const _darkColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primaryCyan,
    onPrimary: AppColors.textInverse,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.accentAmber,
    onSecondary: AppColors.textInverse,
    secondaryContainer: AppColors.accentOrange,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.primaryBlue,
    onTertiary: AppColors.textInverse,
    tertiaryContainer: AppColors.primaryDark,
    onTertiaryContainer: AppColors.textPrimary,
    error: AppColors.statusError,
    onError: AppColors.textPrimary,
    errorContainer: Color(0xFF8B1A10),
    onErrorContainer: Color(0xFFFFDAD4),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceHighlight,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.surfaceHighlight,
    outlineVariant: AppColors.surfaceBright,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.backgroundDark,
    inversePrimary: AppColors.primaryDark,
  );

  // NOTE: The implementing agent must extract the light ColorScheme from the
  // existing lightTheme getter (lines 816-860 approximately) into a similar
  // _lightColorScheme constant.
  static const _lightColorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: AppColors.primaryBlue,
    onPrimary: Colors.white,
    // ... (extract all values from existing lightTheme getter's colorScheme)
  );

  // ==========================================================================
  // THEME BUILDER
  // ==========================================================================

  /// WHY: Single builder eliminates duplication. Each theme just passes its
  /// token set. Component themes reference parameters, not hardcoded colors.
  static ThemeData build({
    required ColorScheme colorScheme,
    required FieldGuideColors colors,
    required FieldGuideSpacing spacing,
    required FieldGuideRadii radii,
    required FieldGuideMotion motion,
    required FieldGuideShadows shadows,
    required Color scaffoldBackgroundColor,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    final primary = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final outline = colorScheme.outline;

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      extensions: [colors, spacing, radii, motion, shadows],

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: shadows.medium,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: primary, size: 24),
        systemOverlayStyle: systemOverlayStyle,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: colors.surfaceElevated,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        elevation: shadows.low,
        margin: EdgeInsets.symmetric(vertical: spacing.xs, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.md),
          side: BorderSide(
            color: outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hoverColor: colors.surfaceElevated,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.sm),
          borderSide: BorderSide(color: outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.sm),
          borderSide: BorderSide(color: outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.sm),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.sm),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.sm),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radii.sm),
          borderSide: BorderSide(
            color: outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 14,
          fontWeight: FontWeight.w500, color: onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 12,
          fontWeight: FontWeight.w600, color: primary,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 14,
          fontWeight: FontWeight.w400, color: colors.textTertiary,
        ),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: colors.surfaceBright,
          disabledForegroundColor: colors.textTertiary,
          elevation: shadows.low,
          shadowColor: primary.withValues(alpha: 0.3),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg, vertical: spacing.md,
          ),
          minimumSize: const Size(88, DesignConstants.touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', fontSize: 15,
            fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.surfaceElevated,
          foregroundColor: onSurface,
          disabledBackgroundColor: colors.surfaceBright,
          disabledForegroundColor: colors.textTertiary,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg, vertical: spacing.md,
          ),
          minimumSize: const Size(88, DesignConstants.touchTargetMin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', fontSize: 15,
            fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: colors.textTertiary,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg, vertical: spacing.md,
          ),
          minimumSize: const Size(88, DesignConstants.touchTargetMin),
          side: BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', fontSize: 15,
            fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: colors.textTertiary,
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md, vertical: DesignConstants.space3,
          ),
          minimumSize: const Size(64, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', fontSize: 14,
            fontWeight: FontWeight.w600, letterSpacing: 0.5,
          ),
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurfaceVariant,
          hoverColor: primary.withValues(alpha: 0.08),
          focusColor: primary.withValues(alpha: 0.12),
          highlightColor: primary.withValues(alpha: 0.12),
          minimumSize: const Size(
            DesignConstants.touchTargetMin, DesignConstants.touchTargetMin,
          ),
          iconSize: 24,
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: onPrimary,
        elevation: shadows.medium,
        focusElevation: shadows.high,
        hoverElevation: shadows.high,
        highlightElevation: shadows.high,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
        extendedTextStyle: const TextStyle(
          fontFamily: 'Roboto', fontSize: 15,
          fontWeight: FontWeight.w700, letterSpacing: 0.5,
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: DesignConstants.touchTargetComfortable,
          height: DesignConstants.touchTargetComfortable,
        ),
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        elevation: shadows.medium,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 28);
          }
          return IconThemeData(color: onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'Roboto', fontSize: 13,
              fontWeight: FontWeight.w700, color: primary,
              letterSpacing: 0.4,
            );
          }
          return TextStyle(
            fontFamily: 'Roboto', fontSize: 12,
            fontWeight: FontWeight.w600, color: onSurfaceVariant,
            letterSpacing: 0.4,
          );
        }),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        elevation: shadows.modal,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
          side: BorderSide(
            color: outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 22,
          fontWeight: FontWeight.w700, color: onSurface,
          letterSpacing: 0.15,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 15,
          fontWeight: FontWeight.w400, color: onSurfaceVariant,
          height: 1.5,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        elevation: shadows.modal,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radii.xl),
          ),
        ),
        dragHandleColor: colors.surfaceBright,
        dragHandleSize: const Size(40, 4),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 15,
          fontWeight: FontWeight.w500, color: onSurface,
        ),
        actionTextColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.md),
          side: BorderSide(
            color: outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        elevation: shadows.medium,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: colors.surfaceBright,
        circularTrackColor: colors.surfaceBright,
      ),

      // Text Theme
      // NOTE: The implementing agent must extract the full TextTheme from the
      // existing dark theme getter. Text colors should use onSurface/onSurfaceVariant
      // parameters. The text theme is identical structure for dark and light — only
      // the color values change (via colorScheme references).
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Roboto', fontSize: 57, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.25, height: 1.12),
        displayMedium: TextStyle(fontFamily: 'Roboto', fontSize: 45, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0, height: 1.16),
        displaySmall: TextStyle(fontFamily: 'Roboto', fontSize: 36, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: 0, height: 1.22),
        headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0, height: 1.25),
        headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0, height: 1.29),
        headlineSmall: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0, height: 1.33),
        titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0, height: 1.27),
        titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0.15, height: 1.50),
        titleSmall: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0.1, height: 1.43),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: 0.5, height: 1.50),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, letterSpacing: 0.25, height: 1.43),
        bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVariant, letterSpacing: 0.4, height: 1.33),
        labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0.1, height: 1.43),
        labelMedium: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: 0.5, height: 1.33),
        labelSmall: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w700, color: onSurfaceVariant, letterSpacing: 0.5, height: 1.45),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.08),
        iconColor: onSurfaceVariant,
        selectedColor: primary,
        textColor: onSurface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md, vertical: spacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.sm),
        ),
        minTileHeight: DesignConstants.touchTargetMin,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceElevated,
        selectedColor: primary.withValues(alpha: 0.24),
        disabledColor: colors.surfaceBright,
        deleteIconColor: onSurfaceVariant,
        labelStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 13,
          fontWeight: FontWeight.w600, color: onSurface,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm, vertical: spacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.sm),
          side: BorderSide(color: outline),
        ),
        side: BorderSide(color: outline),
        checkmarkColor: primary,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return colors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.5);
          }
          return colors.surfaceBright;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: BorderSide(color: onSurfaceVariant, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: colors.surfaceBright,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: TextStyle(
          fontFamily: 'Roboto', fontSize: 14,
          fontWeight: FontWeight.w700, color: onPrimary,
        ),
      ),
    );
  }

  // ==========================================================================
  // THEME GETTERS
  // ==========================================================================

  /// Dark theme — primary field-optimized theme.
  static ThemeData get darkTheme => build(
    colorScheme: _darkColorScheme,
    colors: FieldGuideColors.dark,
    spacing: FieldGuideSpacing.standard,
    radii: FieldGuideRadii.standard,
    motion: FieldGuideMotion.standard,
    shadows: FieldGuideShadows.standard,
    scaffoldBackgroundColor: AppColors.tVividBackground,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  /// Light theme — clean, high-readability theme.
  static ThemeData get lightTheme => build(
    colorScheme: _lightColorScheme,
    colors: FieldGuideColors.light,
    spacing: FieldGuideSpacing.standard,
    radii: FieldGuideRadii.standard,
    motion: FieldGuideMotion.standard,
    shadows: FieldGuideShadows.standard,
    scaffoldBackgroundColor: AppColors.lightBackground,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.lightBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}
```

**IMPORTANT**: The implementing agent MUST:
1. Extract the full `_lightColorScheme` from the existing `lightTheme` getter before deleting it.
2. Preserve every component theme that exists in the current dark/light getters. The code above covers the major ones but the implementing agent should verify against the full existing source (1,264 lines after HC removal) that no component theme is dropped.
3. Ensure the `TabBarTheme`, `PopupMenuThemeData`, `TooltipTheme`, and any other component themes present in the existing code are included in `build()`. If they exist in the current source, they must be parameterized and included.
4. Keep all deprecated re-exports at the top of the class unchanged.

#### Step 1.8.2: Verify theme collapse compiles

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors. The `darkTheme` and `lightTheme` getters produce the same `ThemeData` structure as before, just via a shared builder.

---

### Sub-phase 1.9: Update design system barrel

**Files:**
- Modify: `lib/core/design_system/design_system.dart`

**Agent**: `code-fixer-agent`

#### Step 1.9.1: Update `design_system.dart` to export tokens sub-barrel

```dart
// File: lib/core/design_system/design_system.dart
// Barrel export for the Field Guide design system.
//
// Usage (single import for all components):
// ```dart
// import 'package:construction_inspector/core/design_system/design_system.dart';
// ```

// FROM SPEC: Phase 1 — tokens sub-barrel (new)
export 'tokens/tokens.dart';

// Atomic layer
export 'app_text.dart';
export 'app_text_field.dart';
export 'app_chip.dart';
export 'app_progress_bar.dart';
export 'app_counter_field.dart';
export 'app_toggle.dart';
export 'app_icon.dart';

// Card layer
export 'app_glass_card.dart';
export 'app_section_header.dart';
export 'app_list_tile.dart';
export 'app_photo_grid.dart';
export 'app_section_card.dart';

// Surface layer
export 'app_scaffold.dart';
export 'app_bottom_bar.dart';
export 'app_bottom_sheet.dart';
export 'app_dialog.dart';
export 'app_sticky_header.dart';
export 'app_drag_handle.dart';

// Composite layer
export 'app_empty_state.dart';
export 'app_error_state.dart';
export 'app_loading_state.dart';
export 'app_budget_warning_chip.dart';
export 'app_info_banner.dart';
export 'app_mini_spinner.dart';

// NOTE: Sub-barrels for atoms/, molecules/, organisms/, surfaces/, feedback/,
// layout/, animation/ will be added as those directories are populated in
// later phases. Empty barrel files exist for directory structure.
```

#### Step 1.9.2: Verify barrel update compiles

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors. The tokens barrel re-exports all token files, and the main barrel re-exports the tokens barrel. All 114 consumers of `design_system.dart` now have access to `AppColors`, `DesignConstants`, `FieldGuideColors`, `FieldGuideSpacing`, `FieldGuideRadii`, `FieldGuideMotion`, and `FieldGuideShadows` through the same import.

---

### Sub-phase 1.10: Tokenize existing design system components

**Files:**
- Modify: All 24 existing design system component files in `lib/core/design_system/`

**Agent**: `code-fixer-agent`

#### Step 1.10.1: Update component imports to use co-located tokens

For each of the 24 existing design system components, update their imports. Components that currently import from `lib/core/theme/design_constants.dart` or `lib/core/theme/field_guide_colors.dart` should import from the co-located tokens barrel instead.

The implementing agent should, for each component file in `lib/core/design_system/`:

1. Replace `import 'package:construction_inspector/core/theme/design_constants.dart';` with `import 'tokens/design_constants.dart';` (relative import within design system).
2. Replace `import 'package:construction_inspector/core/theme/field_guide_colors.dart';` with `import 'tokens/field_guide_colors.dart';`.
3. Replace `import 'package:construction_inspector/core/theme/colors.dart';` with `import 'tokens/app_colors.dart';`.

**IMPORTANT**: Do NOT change the actual usage of `DesignConstants.*` within these components yet. Token migration (replacing `DesignConstants.space4` with `FieldGuideSpacing.of(context).md`) will happen as part of screen decomposition in later phases to avoid double-touching files. The components themselves can access the static constants directly since they are inside the design system allowlist.

#### Step 1.10.2: Verify all components compile with updated imports

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors. Import paths changed but all symbols resolve via the same classes.

---

### Sub-phase 1.11: Remove unused testing key for HC theme

**Files:**
- Modify: `lib/shared/testing_keys/settings_keys.dart` (line 90 — comment or keep `settingsThemeHighContrast` for now)
- Modify: `lib/shared/testing_keys/testing_keys.dart` (lines 434-435 — comment or keep for backward compat)

**Agent**: `code-fixer-agent`

#### Step 1.11.1: Mark HC testing key as unused

In `lib/shared/testing_keys/settings_keys.dart`, add a deprecation annotation:

```dart
// At line 90, change:
//   static const settingsThemeHighContrast = Key('settings_theme_high_contrast');
// To:
  @Deprecated('HC theme removed in Design System Overhaul Phase 1')
  static const settingsThemeHighContrast = Key('settings_theme_high_contrast');
```

Similarly in `lib/shared/testing_keys/testing_keys.dart`:

```dart
// At lines 434-435, change:
//   static const settingsThemeHighContrast =
//       SettingsTestingKeys.settingsThemeHighContrast;
// To:
  @Deprecated('HC theme removed in Design System Overhaul Phase 1')
  static const settingsThemeHighContrast =
      SettingsTestingKeys.settingsThemeHighContrast;
```

// WHY: Deprecate rather than delete to avoid breaking any driver tests that may reference these keys. The keys will be removed in a later cleanup sweep.

#### Step 1.11.2: Final Phase 1 verification

```
pwsh -Command "flutter analyze"
```

**Expected**: Zero errors. Deprecation warnings for the HC testing keys are acceptable. All Phase 0 lint rule warnings are expected and serve as the violation inventory baseline.
