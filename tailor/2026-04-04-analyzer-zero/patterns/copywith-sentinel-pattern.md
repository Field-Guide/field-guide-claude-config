# Pattern: CopyWith Sentinel Pattern

## How We Do It
Every data model uses a hand-written `copyWith()` method with an `Object? _sentinel` trick to distinguish "not passed" from "passed as null". The cast from `Object?` to the target type triggers `cast_nullable_to_non_nullable`. This pattern appears in ~35 model classes generating ~220 violations.

## Exemplars

### Location (lib/features/locations/data/models/location.dart:32)

```dart
static const _sentinel = Object();

Location copyWith({
    Object? name = _sentinel,
    Object? description = _sentinel,
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    Object? createdByUserId = _sentinel,
  }) {
    return Location(
      id: id,
      projectId: projectId,
      name: identical(name, _sentinel) ? this.name : name! as String,           // <-- cast_nullable_to_non_nullable
      description: identical(description, _sentinel) ? this.description : description as String?,  // OK (nullable target)
      latitude: identical(latitude, _sentinel) ? this.latitude : latitude as double?,  // OK
      longitude: identical(longitude, _sentinel) ? this.longitude : longitude as double?,  // OK
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdByUserId: identical(createdByUserId, _sentinel) ? this.createdByUserId : createdByUserId as String?,  // OK
    );
  }
```

**Key insight**: Only non-nullable target types trigger the lint. `as String?` is fine. `as String` on `Object?` triggers it.

### SyncResult (lib/features/sync/domain/sync_types.dart:27)

Same pattern with more fields:
```dart
SyncResult copyWith({
    Object? pushed = _sentinel,
    Object? pulled = _sentinel,
    Object? errors = _sentinel,
    Object? errorMessages = _sentinel,
    Object? rlsDenials = _sentinel,
    Object? skippedPush = _sentinel,
  })
```

## Affected Model Classes (35 total)

**PDF extraction models (~25):** CellGrid, Cell, ClassifiedRow, ClassifiedRows, ColumnSpec, ColumnMap, ConfidenceScore, FieldConfidence, DetectedRegion, DetectedRegions, DocumentChecksum, DocumentProfile, DocumentProfileHeader, UnifiedExtractionResult, OcrElement, OcrPage, ParsedItem, ParsedItems, PipelineConfig, ProcessedItems, QualityReport, SidecarEntry, Sidecar, StageReport, PipelineResult, TesseractConfigV2

**Data models (~10):** Company, CompanyJoinRequest, UserProfile, CalculationHistory, FormResponse, InspectorForm, ConsentRecord, SupportTicket, TodoItem, ColumnDrift

## Imports
```dart
// No additional imports needed for the sentinel pattern itself.
// The _sentinel is a file-private constant.
```
