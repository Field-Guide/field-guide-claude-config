# Pattern: Barrel Export

## How We Do It
Each module/directory has a barrel file (usually named after the directory or `widgets.dart`/`screens.dart`) that re-exports all public files. Consumers import the single barrel. This enables internal file restructuring without breaking consumer imports.

## Exemplar: Design System Barrel (`lib/core/design_system/design_system.dart`)

```dart
// Barrel export for the Field Guide design system.
// Usage: import 'package:construction_inspector/core/design_system/design_system.dart';

// Atomic layer
export 'app_text.dart';
export 'app_text_field.dart';
export 'app_chip.dart';
// ... 24 total exports
```

## Exemplar: Shared Widgets Barrel (`lib/shared/widgets/widgets.dart`)

```dart
library;

export 'confirmation_dialog.dart';
export 'contextual_feedback_overlay.dart';
export 'empty_state_widget.dart';
export 'permission_dialog.dart';
export 'search_bar_field.dart';
export 'stale_config_warning.dart';
export 'version_banner.dart';
```

## Target: New Barrel Structure

```dart
// lib/core/design_system/design_system.dart (main barrel)
export 'tokens/tokens.dart';
export 'atoms/atoms.dart';
export 'molecules/molecules.dart';
export 'organisms/organisms.dart';
export 'surfaces/surfaces.dart';
export 'feedback/feedback.dart';
export 'layout/layout.dart';
export 'animation/animation.dart';

// lib/core/design_system/tokens/tokens.dart (sub-barrel)
export 'app_colors.dart';
export 'design_constants.dart';
export 'field_guide_colors.dart';
export 'field_guide_spacing.dart';
export 'field_guide_radii.dart';
export 'field_guide_motion.dart';
export 'field_guide_shadows.dart';
```

## Migration Strategy
1. Create new subdirectory barrel files
2. Move files to subdirectories
3. Update main barrel to re-export sub-barrels
4. Run `dart fix --apply` per batch
5. Verify zero analyzer errors

**Key insight**: If the main barrel path stays the same (`design_system.dart`) and re-exports everything, the 114 consumer files don't need import changes. Only internal design system files need relative import updates.
