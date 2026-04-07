---
feature: quantities
type: overview
scope: Bid Items & Quantity Tracking
updated: 2026-04-07
---

# Quantities Feature Overview

## Purpose

The quantities feature manages project bid items and entry-level completed
quantities for budget and progress tracking.

## Current UI Structure

- `quantities_providers.dart` owns long-lived bid-item and quantity providers
- `quantity_screen_providers.dart` owns calculator/detail controller scopes
- `EntryQuantityProvider` is split into action and query surfaces
- `BidItemProvider` keeps batch import logic extracted into `bid_item_batch_import.dart`

## Key Files

| File | Purpose |
|------|---------|
| `lib/features/quantities/di/quantities_providers.dart` | Root quantities DI wiring |
| `lib/features/quantities/di/quantity_screen_providers.dart` | Screen-local controller scopes |
| `lib/features/quantities/presentation/providers/bid_item_provider.dart` | Bid item state |
| `lib/features/quantities/presentation/providers/entry_quantity_provider.dart` | Entry quantity state |
| `lib/features/quantities/presentation/controllers/quantity_calculator_controller.dart` | Calculator controller |
| `lib/features/quantities/presentation/screens/quantities_screen.dart` | Quantities shell |
| `lib/features/quantities/presentation/screens/quantity_calculator_screen.dart` | Calculator shell |

## Integration Points

- entries depend on quantities for per-entry logging
- dashboard depends on quantities for budget summaries
- sync verification depends on the quantities screen contract staying stable
