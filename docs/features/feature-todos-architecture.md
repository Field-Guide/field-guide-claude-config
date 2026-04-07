---
feature: todos
type: architecture
updated: 2026-04-07
---

# Todos Feature Architecture

Todos remains a straightforward CRUD feature, but the provider now follows the
same bounded-surface pattern as the rest of the refactored UI stack.

## Directory Structure

```text
lib/features/todos/
├── di/
│   └── todos_providers.dart
├── data/
├── domain/
└── presentation/
    ├── providers/
    │   ├── todo_provider.dart
    │   ├── todo_provider_actions.dart
    │   ├── todo_provider_filters.dart
    │   └── todo_sorting.dart
    └── screens/
        └── todos_screen.dart
```

## Provider Shape

`TodoProvider` remains the main orchestration layer for:
- todo CRUD
- project scoping
- filter/sort state
- viewer-role write guard

But implementation details are now split into:
- action methods
- filter/query state
- sorting helpers

That keeps the provider API stable without allowing it to regrow into another
large presentation class.

## DI Wiring

`di/todos_providers.dart` still owns root feature wiring for `TodoProvider`.
No screen-local controller scope is needed here yet because the screen remains
simple enough to stay thin without it.

## Relationships

- `AuthProvider.canEditFieldData` is still injected as the write guard
- `ProjectProvider` still scopes the todo list to the active project
- toolbox and entries continue to read todo data through the same provider

## Key Files

- `lib/features/todos/di/todos_providers.dart`
- `lib/features/todos/presentation/providers/todo_provider.dart`
- `lib/features/todos/presentation/providers/todo_provider_actions.dart`
- `lib/features/todos/presentation/providers/todo_provider_filters.dart`
- `lib/features/todos/presentation/providers/todo_sorting.dart`
- `lib/features/todos/presentation/screens/todos_screen.dart`
