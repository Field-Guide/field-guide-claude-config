# Source Excerpts by Concern

## Phase 1: analysis_options.yaml Changes

File: `analysis_options.yaml`

Lines to modify:
- Line 57: `do_not_use_environment: true` — change to `do_not_use_environment: false` or remove
- Line 65: `strict_raw_type: true` — remove (undefined lint)
- Line 78: `avoid_catches_without_on_clauses: true` — keep, but add test exclusion

Add to analyzer.exclude section (after line 20):
```yaml
  # Per-rule exclusions for test code
  # Note: analysis_options.yaml doesn't support per-rule excludes natively.
  # Option A: Use ignore_for_file in test barrel
  # Option B: Create analysis_options_test.yaml that overrides
```

**Important**: Dart's `analysis_options.yaml` does NOT support per-rule per-directory exclusions natively. Options:
1. Add `// ignore_for_file: avoid_catches_without_on_clauses` to each test file (65 files — tedious)
2. Create `test/analysis_options.yaml` that includes the root and overrides the rule
3. Fix test code too (change `catch (e)` to `on Exception catch (e)` in tests — same mechanical fix)

**Recommendation**: Option 3 (fix in tests too) is simplest and most consistent. The test violations are all mechanical `catch (e)` → `on Exception catch (e)`.

## Phase 3: SafeRow Extension Target Files

Files needing SafeRow import + method replacement:

| File | ~Violations | Primary pattern |
|------|:-----------:|-----------------|
| `lib/core/database/database_service.dart` | 20 | PRAGMA info, migration row access |
| `lib/features/sync/engine/sync_engine.dart` | 9 | Query row iteration |
| `lib/features/sync/engine/change_tracker.dart` | 6 | COUNT aggregates, row access |
| `lib/features/sync/engine/integrity_checker.dart` | ~4 | COUNT, validation queries |
| `lib/core/database/schema_verifier.dart` | ~3 | PRAGMA columns |
| `lib/core/driver/driver_server.dart` | ~5 | Test driver queries |
| `lib/services/project_lifecycle_service.dart` | ~8 | Cascade operations |
| Various local datasources | ~15 | Row field extraction |
| Test files | ~40 | Query assertions |

## Phase 4: SafeAction Mixin Target Providers

Providers that will mix in SafeAction (those with `_isLoading`/`_error` + try/catch/finally):

**High-violation standalone providers** (not extending BaseListProvider):
- TodoProvider (12 catches)
- AuthProvider (12 catches)
- EntryQuantityProvider (11 catches)
- ProjectProvider (10 catches)
- AdminProvider (9 catches)
- EquipmentProvider (7 catches)
- AppConfigProvider (7 catches)

**Providers with multiple loading states** (may need partial adoption):
- DailyEntryProvider (extends BaseListProvider, but adds custom loading states)
- PhotoProvider (has `_isUploading` in addition to `_isLoading`)

**Providers likely too simple for SafeAction** (1-2 catches, no _isLoading):
- WeatherProvider, ThemeProvider, CalendarFormatProvider

## Phase 5: RepositoryResult.safeCall Target Repositories

Simple wrapper methods that become one-liners with safeCall:
- FormResponseRepositoryImpl: 15 of 21 methods are pure wrappers
- InspectorFormRepositoryImpl: ~10 of 13 methods
- PhotoRepositoryImpl: ~8 of 12 methods

Methods with validation logic BEFORE the datasource call (createResponse, submitResponse, markAsExported) need to keep their own try/catch since validation happens before the datasource call.

## Phase 6: CopyWith Sentinel Suppression Targets

PDF extraction models (suppress with `// ignore:` since these are stable):
All in `lib/features/pdf/services/extraction/models/`:
- classified_rows.dart, cell_grid.dart, confidence.dart, detected_regions.dart
- document_profile.dart, extraction_result.dart, ocr_element.dart, parsed_items.dart
- pipeline_config.dart, processed_items.dart, quality_report.dart, sidecar.dart
- stage_report.dart, document_checksum.dart

Data models (consider Value<T> wrapper or suppress):
- `lib/features/auth/data/models/company.dart`
- `lib/features/auth/data/models/company_join_request.dart`
- `lib/features/auth/data/models/user_profile.dart`
- `lib/features/calculator/data/models/calculation_history.dart`
- `lib/features/forms/data/models/form_response.dart`
- `lib/features/forms/data/models/inspector_form.dart`
- `lib/features/settings/data/models/consent_record.dart`
- `lib/features/settings/data/models/support_ticket.dart`
- `lib/features/todos/data/models/todo_item.dart`
- `lib/core/database/schema_verifier.dart` (ColumnDrift)
