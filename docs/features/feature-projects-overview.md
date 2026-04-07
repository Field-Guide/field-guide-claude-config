---
feature: projects
type: overview
scope: Project Management & Setup
updated: 2026-04-07
---

# Projects Feature Overview

## Purpose

Projects remain the central context entity in the app. Every other major
feature scopes data to a project.

## Key Responsibilities

- project creation and editing
- project selection for downstream features
- assignment-aware filtering for inspectors
- remote import and sync enrollment
- per-project sync health

## Current UI Structure

- `projects_providers.dart` owns long-lived project state
- `project_screen_providers.dart` owns setup/list screen controller scopes
- `ProjectProvider` is split by auth init, loading, filtering, mutation, and selection
- project setup behavior is split across controller, loader, save service, and back handler files

## Key Files

| File | Purpose |
|------|---------|
| `lib/features/projects/di/projects_providers.dart` | Root project DI wiring |
| `lib/features/projects/di/project_screen_providers.dart` | Screen-local project controller scopes |
| `lib/features/projects/presentation/providers/project_provider.dart` | Core project state |
| `lib/features/projects/presentation/providers/project_sync_health_provider.dart` | Per-project sync health |
| `lib/features/projects/presentation/providers/project_import_runner.dart` | Remote import state machine |
| `lib/features/projects/presentation/controllers/project_setup_controller.dart` | Setup wizard state |
| `lib/features/projects/presentation/screens/project_list_screen.dart` | Project list shell |
| `lib/features/projects/presentation/screens/project_setup_screen.dart` | Project setup shell |

## Integration Points

- entries, forms, quantities, photos, dashboard, and sync all depend on project selection
- project list and project setup remain important sync-visible screens
