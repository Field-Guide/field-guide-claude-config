---
feature: quantities
type: architecture
scope: Bid Items & Quantity Tracking
updated: 2026-04-07
---

# Quantities Feature Architecture

The quantities feature still models project-level bid items and entry-level
usage records, but its presentation layer now follows the same decomposition
rules as the rest of the design-system refactor.

## Directory Layout

```text
lib/features/quantities/
├── di/
│   ├── quantities_providers.dart
│   └── quantity_screen_providers.dart
├── data/
├── domain/
└── presentation/
    ├── providers/
    │   ├── bid_item_provider.dart
    │   ├── bid_item_batch_import.dart
    │   ├── entry_quantity_provider.dart
    │   ├── entry_quantity_provider_actions.dart
    │   └── entry_quantity_provider_queries.dart
    ├── controllers/
    │   ├── quantity_calculator_controller.dart
    │   └── bid_item_detail_controller.dart
    ├── screens/
    └── widgets/
```

## Root DI vs Screen DI

### `di/quantities_providers.dart`

Registers long-lived feature providers:
- `BidItemProvider`
- `EntryQuantityProvider`

### `di/quantity_screen_providers.dart`

Registers screen-local controller scopes:
- `QuantityCalculatorControllerScope`
- `BidItemDetailControllerScope`

This keeps transient quantity-calculator and detail-sheet state out of the
screen widgets themselves.

## Providers

### BidItemProvider

Still owns project-scoped bid-item state, search, paging, and import flows.
Batch import logic is extracted into `bid_item_batch_import.dart` so import
behavior does not dominate the provider file.

### EntryQuantityProvider

Now split into:
- `entry_quantity_provider_actions.dart`
- `entry_quantity_provider_queries.dart`

The provider still owns:
- current-entry quantities
- used-by-bid-item cache
- bulk save/delete flows
- per-entry and per-project query surfaces

But write/query responsibilities are no longer collapsed into one large file.

## Controllers

### QuantityCalculatorController

Owns calculator-screen transient state and stays screen-local through
`quantity_screen_providers.dart`.

### BidItemDetailController

Owns detail-sheet state and wizard-activity integration without pushing that
logic into the sheet widget or the main providers.

## Key Patterns

### Two-Tier Model

- `BidItem` is project-level contract scope
- `EntryQuantity` is per-entry usage against a bid item

The separation remains important for sync, dashboard reporting, and entry UI.

### Query / Mutation Split

The refactor intentionally split cached queries and mutation flows so quantity
providers stay uniform with the rest of the app’s bounded presentation API
pattern.

### Sync / Driver Relevance

`QuantitiesScreen` is part of the sync-relevant UI surface. Its root sentinel,
screen contract, and flow definitions must move together whenever the screen
shell or route changes.

## Key Files

- `lib/features/quantities/di/quantities_providers.dart`
- `lib/features/quantities/di/quantity_screen_providers.dart`
- `lib/features/quantities/presentation/providers/bid_item_provider.dart`
- `lib/features/quantities/presentation/providers/entry_quantity_provider.dart`
- `lib/features/quantities/presentation/controllers/quantity_calculator_controller.dart`
- `lib/features/quantities/presentation/controllers/bid_item_detail_controller.dart`
- `lib/features/quantities/presentation/screens/quantities_screen.dart`
- `lib/features/quantities/presentation/screens/quantity_calculator_screen.dart`
