# Dependency Graph

## Files Being Modified/Created

### New Files
| File | Purpose |
|------|---------|
| `lib/shared/utils/safe_row.dart` | SafeRow extension on `Map<String, Object?>` |
| `lib/shared/providers/safe_action_mixin.dart` | SafeAction mixin on ChangeNotifier |

### Modified Files (Key)
| File | Change | Phase |
|------|--------|-------|
| `analysis_options.yaml` | Remove `do_not_use_environment`, `strict_raw_type`; add test exclusions | 1 |
| `lib/shared/repositories/base_repository.dart` | Add `RepositoryResult.safeCall()` static method | 5 |
| `lib/shared/providers/base_list_provider.dart` | Replace bare catches with `on Exception catch` | 2A/4 |
| `lib/shared/providers/paged_list_provider.dart` | Replace bare catches with `on Exception catch` | 2A |
| 30+ provider files | Replace bare catches; optionally adopt SafeAction mixin | 2A/4 |
| 6+ repository impl files | Replace bare catches; optionally adopt RepositoryResult.safeCall | 2A/5 |
| 35 model files | Add `@immutable` annotation | 2B |
| 18 PDF stage files | Replace `$runtimeType` with `StageNames.*` | 2C |

## Import Graph: RepositoryResult

```
lib/shared/repositories/base_repository.dart (defines RepositoryResult)
  ├── 51 direct importers (confirmed: 49 with name references)
  │   ├── 19 repository impls (data layer)
  │   ├── 13 domain interfaces
  │   ├── 7 use cases
  │   ├── 2 base providers
  │   └── 10 test files
  └── 62 potential importers (via barrel/wildcard imports)
      ├── 15 providers
      ├── 12 DI files
      ├── 8 use cases
      ├── 5 services
      └── 22 test files
```

**Total blast radius**: 111 files (risk score: 0.79)

## Import Graph: BaseListProvider

```
lib/shared/providers/base_list_provider.dart
  extends ChangeNotifier
  imports: base_repository.dart, logger.dart

  Descendants (6):
  ├── ContractorProvider (contractor_provider.dart)
  ├── LocationProvider (location_provider.dart)
  ├── PersonnelTypeProvider (personnel_type_provider.dart)
  ├── DailyEntryProvider (daily_entry_provider.dart)
  ├── BidItemProvider (bid_item_provider.dart)
  └── TestBidItemProvider (test only)
```

## Standalone ChangeNotifier Providers (not extending BaseListProvider)

These are the providers that need individual catch fixes and SafeAction mixin consideration:

| Provider | File | Catch violations |
|----------|------|:---:|
| TodoProvider | `lib/features/todos/presentation/providers/todo_provider.dart` | 12 |
| AuthProvider | `lib/features/auth/presentation/providers/auth_provider.dart` | 12 |
| EntryQuantityProvider | `lib/features/quantities/presentation/providers/entry_quantity_provider.dart` | 11 |
| ProjectProvider | `lib/features/projects/presentation/providers/project_provider.dart` | 10 |
| AdminProvider | `lib/features/settings/presentation/providers/admin_provider.dart` | 9 |
| EquipmentProvider | `lib/features/contractors/presentation/providers/equipment_provider.dart` | 7 |
| AppConfigProvider | `lib/features/auth/presentation/providers/app_config_provider.dart` | 7 |
| PhotoProvider | `lib/features/photos/presentation/providers/photo_provider.dart` | ~5 |
| ConsentProvider | `lib/features/settings/presentation/providers/consent_provider.dart` | 4 |
| CalendarFormatProvider | `lib/features/entries/presentation/providers/calendar_format_provider.dart` | ~2 |
| GalleryProvider | `lib/features/gallery/presentation/providers/gallery_provider.dart` | 1 |
| SyncProvider | `lib/features/sync/presentation/providers/sync_provider.dart` | ~3 |
| InspectorFormProvider | `lib/features/forms/presentation/providers/inspector_form_provider.dart` | ~3 |
| DocumentProvider | `lib/features/forms/presentation/providers/document_provider.dart` | ~2 |
| EntryExportProvider | `lib/features/entries/presentation/providers/entry_export_provider.dart` | ~2 |
| SupportProvider | `lib/features/settings/presentation/providers/support_provider.dart` | ~2 |
| WeatherProvider | `lib/features/weather/presentation/providers/weather_provider.dart` | ~2 |
| ThemeProvider | `lib/features/settings/presentation/providers/theme_provider.dart` | 0 |
| FormExportProvider | `lib/features/forms/presentation/providers/form_export_provider.dart` | ~1 |
| ProjectAssignmentProvider | `lib/features/projects/presentation/providers/project_assignment_provider.dart` | ~2 |
| ProjectSettingsProvider | `lib/features/projects/presentation/providers/project_settings_provider.dart` | ~1 |
| ProjectSyncHealthProvider | `lib/features/projects/presentation/providers/project_sync_health_provider.dart` | ~1 |
| ProjectImportRunner | `lib/features/projects/presentation/providers/project_import_runner.dart` | ~2 |
| CalculatorProvider | `lib/features/calculator/presentation/providers/calculator_provider.dart` | 3 |
| ExtractionJobRunner | `lib/features/pdf/services/extraction/runner/extraction_job_runner.dart` | ~2 |

## Data Flow: SafeAction Mixin Integration

```
SafeAction mixin (new)
  └── mixed into ChangeNotifier subclasses
      ├── Provides: _isLoading, _error, isLoading, error, safeAction(), safeGet()
      ├── Replaces: manual _isLoading/_error fields + try/catch/finally blocks
      └── Constraint: providers with multiple loading states need variant or partial adoption
```
