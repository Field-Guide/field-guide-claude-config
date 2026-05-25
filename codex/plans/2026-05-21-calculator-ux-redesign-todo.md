# Calculator UX Redesign To-Do Spec

## Summary

Redesign calculators around a professional Calculator Hub with four families:
HMA, Area, Trench Layer, and Regular Calculator. Start with wireframes and
colored HTML mockups; after approval, implement in Flutter and use
emulator/device rendering with hot restart for visual iteration.

## To-Do List

- [ ] Create a Calculator Hub opened from the Toolbox Calculator button.
- [ ] Show four calculator family rows:
  - [ ] HMA Calculator
  - [ ] Area Calculator
  - [ ] Trench Layer Calculator
  - [ ] Regular Calculator

- [ ] Redesign HMA Calculator.
  - [ ] Split HMA Yield and Weighback into internal tabs or segmented modes.
  - [ ] Use the shared shape engine for HMA area input.
  - [ ] Keep existing yield and weighback functionality.
  - [ ] Preserve save-to-history behavior.

- [ ] Redesign Area Calculator.
  - [ ] Support rectangle, square, triangle, trapezoid, and circle.
  - [ ] Support SF, SY, CF, and CY outputs.
  - [ ] Add optional depth/thickness for cubic calculations.
  - [ ] Show live 2D top-down diagrams.
  - [ ] Show depth/thickness callout and small volume preview when cubic mode
    is active.
  - [ ] Allow one active editable shape at a time.
  - [ ] Add shapes into a compact running total list.
  - [ ] Let total-list rows be edited, duplicated, and deleted.

- [ ] Redesign Trench Layer Calculator.
  - [ ] Show a trench cross-section diagram.
  - [ ] Support length, top width, bottom width, total depth, and layer depths.
  - [ ] Show compact per-layer totals and final total.
  - [ ] Validate that layer depths match the total trench depth.
  - [ ] Preserve save-to-history behavior.

- [ ] Add Regular Calculator.
  - [ ] Support construction-basic arithmetic.
  - [ ] Include add, subtract, multiply, divide, decimal, percent, clear, and
    backspace.
  - [ ] Support result handoff when launched from pay-item quantity flow.
  - [ ] Add persistent calculation history.

- [ ] Update daily-entry Pay Items Used flow.
  - [ ] Remove the current calculator-first workflow.
  - [ ] User taps Add pay item first.
  - [ ] User selects a pay item.
  - [ ] Show selected-item sheet with item number, description, unit, bid
    quantity, used quantity, and remaining quantity.
  - [ ] Keep pay item description visible.
  - [ ] Add manual quantity field.
  - [ ] Add Calculator action.
  - [ ] Calculator result returns to the selected-item sheet and fills the
    quantity field.
  - [ ] User confirms Add before the quantity is saved.
  - [ ] Do not auto-save formula text into quantity notes.
  - [ ] Keep quantity notes user-authored only.

- [ ] Add selected-pay-item calculator rules.
  - [ ] Use Area Calculator by default for compatible units.
  - [ ] Match result unit to pay item unit when possible.
  - [ ] Suggest Regular Calculator for non-geometric/weird units.
  - [ ] Do not mutate the pay item unit.

- [ ] Create wireframes first.
  - [ ] Add low-fidelity HTML wireframes under `mockups/`.
  - [ ] Include phone portrait layout.
  - [ ] Include tablet landscape layout.
  - [ ] Show Calculator Hub, Area Calculator, HMA modes, Trench Layer, Regular
    Calculator, and selected-pay-item flow.
  - [ ] Keep wireframes mostly structural before adding final colors.

- [ ] After wireframe approval, create colored HTML mockups.
  - [ ] Use Field Guide palette and app-like navigation chrome.
  - [ ] Use realistic construction values.
  - [ ] Use inline SVG diagrams for shapes, dimensions, depth, and trench
    layers.

- [ ] After mockup approval, implement in Flutter.
  - [ ] Render on emulator/device for visual review.
  - [ ] Iterate with Flutter hot restart/reload.
  - [ ] Capture screenshots for phone portrait and tablet landscape review.
  - [ ] Adjust spacing, density, diagrams, and flow based on rendered app
    behavior.

## Test To-Dos

- [ ] Add widget tests for Calculator Hub navigation.
- [ ] Add Area Calculator tests for all shapes.
- [ ] Add Area Calculator tests for SF/SY/CF/CY conversion.
- [ ] Add multi-shape total tests.
- [ ] Add edit, duplicate, and delete tests for saved shape rows.
- [ ] Add HMA tests proving shared shape-engine behavior.
- [ ] Add HMA yield and weighback regression tests.
- [ ] Add Trench Layer depth validation and total tests.
- [ ] Add Regular Calculator arithmetic and history tests.
- [ ] Add entry quantity tests for selected-pay-item-first flow.
- [ ] Add tests for compatible unit defaults.
- [ ] Add tests for non-geometric unit Regular Calculator suggestion.
- [ ] Add tests proving quantity notes remain user-authored.
- [ ] Verify responsive layout on S21 portrait and tablet landscape.
- [ ] Run emulator/device visual verification after Flutter implementation.

## Assumptions

- "UE" means UX/user experience.
- First implementation excludes irregular polygon, oval/ellipse, and
  scientific calculator features.
- HMA and Trench are standalone convenience calculators unless launched
  directly from the hub.
- Area Calculator is the primary quantity-writeback calculator.

## HMA Lane-Only Taper Addendum

- HMA yield/weighback geometry is one lane only, not full-road or centered
  pavement.
- Left and right are interpreted looking down station.
- Add a lane-side control for HMA:
  - Left of CL / Joint
  - Right of CL / Joint
- The CL / Joint edge is fixed. Width is measured outward from that edge, and
  the rendered/calculated pavement must never cross centerline.
- The HMA diagram should shade only the lane side being calculated.
- Do not add draggable corner handles for the first implementation. Numeric
  fields are enough now that the centerline/joint model is clear.
- HMA Yield keeps the existing workflow and fields but changes the taper
  renderer/model to one-sided lane geometry:
  - Base length
  - Start width
  - Thickness
  - Truck mix weight
  - Optional taper end length
  - Optional end width
- HMA Weighback calculates the remaining unpaved lane section, not the already
  paved section.
- HMA Weighback should support taper because remaining work may taper.
- HMA Weighback uses mix weight only. It should not add gross/tare ticket
  fields unless requested later.
- HMA Weighback should calculate/show:
  - Truck mix weight
  - Length/width or tapered remaining geometry
  - Area left to go
  - Tons needed for the remaining section
  - Mix left in the truck afterward
- Yield and Weighback should share the same HMA lane-shape model and diagram
  behavior wherever practical.
