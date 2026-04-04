# Ground Truth Verification

All string literals, file paths, and symbol names verified against the actual codebase.

## Database Columns

| Literal | Source File | Line | Status |
|---------|-----------|------|--------|
| `'location_id'` (in toMap) | `lib/features/entries/data/models/daily_entry.dart` | 114 | VERIFIED |
| `'location_id'` (in fromMap) | `lib/features/entries/data/models/daily_entry.dart` | 162 | VERIFIED |
| `'activities'` (in toMap) | `lib/features/entries/data/models/daily_entry.dart` | 119 | VERIFIED |
| `'activities'` (in fromMap) | `lib/features/entries/data/models/daily_entry.dart` | 169 | VERIFIED |
| `location_id TEXT` (schema) | `lib/core/database/schema/entry_tables.dart` | 10 | VERIFIED |
| `ON DELETE SET NULL` (FK) | `lib/core/database/schema/entry_tables.dart` | 36 | VERIFIED |

## DailyEntry Model

| Literal | Source File | Line | Status |
|---------|-----------|------|--------|
| `locationId` (field type: `String?`) | `daily_entry.dart` | 10 | VERIFIED |
| `activities` (field type: `String?`) | `daily_entry.dart` | 16 | VERIFIED |
| `locationId` param in `copyWith` | `daily_entry.dart` | 65 | VERIFIED |
| `getMissingFields()` checks `locationId == null` | `daily_entry.dart` | 143 | VERIFIED |
| Missing field string: `'location'` | `daily_entry.dart` | 143 | VERIFIED |

## Sync Adapter

| Literal | Source File | Line | Status |
|---------|-----------|------|--------|
| `tableName: 'daily_entries'` | `daily_entry_adapter.dart` | 10 | VERIFIED |
| FK deps: `['projects', 'locations']` | `daily_entry_adapter.dart` | 13 | VERIFIED |
| `fkColumnMap: {'projects': 'project_id', 'locations': 'location_id'}` | `daily_entry_adapter.dart` | 18-21 | VERIFIED |
| `scopeType: ScopeType.viaProject` | `daily_entry_adapter.dart` | 11 | VERIFIED |
| `userStampColumns: {'updated_by_user_id': 'current'}` | `daily_entry_adapter.dart` | 28 | VERIFIED |

## PDF Field Names (Current Mappings — to be rebuilt)

| Field Name | Maps To | Source Line | Status |
|-----------|---------|------------|--------|
| `'Text10'` | Date | `pdf_service.dart:88` | VERIFIED (code exists, visual position unverified) |
| `'Text11'` | Project # | `pdf_service.dart:90` | VERIFIED (unverified position) |
| `'Text15'` | Project Name | `pdf_service.dart:91` | VERIFIED (unverified position) |
| `'Text12'` | Weather | `pdf_service.dart:92` | VERIFIED (unverified position) |
| `'Text13'` | Temp Range | `pdf_service.dart:93` | VERIFIED (unverified position) |
| `'Text3'` | Activities | `pdf_service.dart:110` | VERIFIED (unverified position) |
| `'asfdasdfWER'` | Site Safety | `pdf_service.dart:115` | VERIFIED (code comment says "guessing") |
| `'HJTYJH'` | SESC Measures | `pdf_service.dart:116` | VERIFIED (code comment says "guessing") |
| `'Text5#loioliol0'` | Traffic Control | `pdf_service.dart:117` | VERIFIED (unverified position) |
| `'iol8ol'` | Visitors | `pdf_service.dart:118` | VERIFIED (unverified position) |
| `'8olyk,l'` | Materials | `pdf_service.dart:121` | VERIFIED (code comment says "guessing") |
| `'Text6'` | Attachments | `pdf_service.dart:127` | VERIFIED (comment says "verified from debug PDF") |
| `'yio'` | Extras & Overruns | `pdf_service.dart:128` | VERIFIED (not currently populated) |
| `'hhhhhhhhhhhwerwer'` | Signature | `pdf_service.dart:131` | VERIFIED (unverified position) |

## Contractor Field Map

| Index | Name Field | Foreman | Operator | Laborer | Status |
|-------|-----------|---------|----------|---------|--------|
| 0 (Prime) | `Namegdzf` | `QntyForeman` | `QntyOperator` | `QntyLaborer` | VERIFIED |
| 1 (Sub 1) | `sfdasd` | `null` | `null` | `null` | VERIFIED (no personnel fields) |
| 2 (Sub 2) | `Name_3dfga` | `QntyForeman_3` | `QntyOperator_3` | `QntyLaborer_3` | VERIFIED |
| 3 (Sub 3) | `Name_31345145` | `QntyForeman_4` | `QntyOperator_4` | `QntyLaborer_4` | VERIFIED |
| 4 (Sub 4) | `Name_3234523` | `QntyForeman_5` | `QntyOperator_5` | `QntyLaborer_5` | VERIFIED |

## Equipment Field Map

| Index | Slot 1 | Slot 2 | Slot 3 | Slot 4 | Slot 5 | Status |
|-------|--------|--------|--------|--------|--------|--------|
| 0 | `ggggsssssssssss` | `3#aaaaaaaaaaa0` | `3#0asfdasfd` | `4` | `3ggggggg` | VERIFIED |
| 1 | `8888888888888` | `\\\\\\\\\\\\` | `'''''''''''` | `[[[[[[[[[[[[[` | `vvvvvvvvvvvv` | VERIFIED |
| 2 | `4_3234` | `5_323423` | `4_32456246` | `5_346345` | `5_323452345` | VERIFIED |
| 3 | `12431243` | `5_3234556467` | `4_4567456` | `5_34567` | `5_312342342` | VERIFIED |
| 4 | `4_53674` | `2352345` | `4_3234534` | `5_32352345` | `5_34563456` | VERIFIED |

## Testing Keys

| Key | Source File | Line | Status |
|-----|-----------|------|--------|
| `TestingKeys.reportActivitiesSection` | `testing_keys.dart` | 640-641 | VERIFIED |
| `TestingKeys.reportActivitiesField` | `testing_keys.dart` | 642 | VERIFIED |
| `TestingKeys.locationOption(id)` | `testing_keys.dart` | 752-753 | VERIFIED |

## Enums

| Enum | Values | Source File | Line | Status |
|------|--------|-----------|------|--------|
| `EntryFilterType` | `dateRange, location, status` | `daily_entry_provider.dart` | 14 | VERIFIED |
| `WeatherCondition` | `sunny, cloudy, overcast, rainy, snow, windy` | `daily_entry.dart` | 1-3 | VERIFIED |

## File Paths

| Path | Exists | Status |
|------|--------|--------|
| `assets/templates/idr_template.pdf` | Yes | VERIFIED |
| `.claude/skills/pdf-processing/scripts/extract_form_field_info.py` | Yes | VERIFIED |
| `.claude/skills/pdf-processing/scripts/fill_fillable_fields.py` | Yes | VERIFIED |
| `.claude/skills/pdf-processing/scripts/convert_pdf_to_images.py` | Yes | VERIFIED |
| `.claude/skills/pdf-processing/scripts/fill_pdf_form_with_annotations.py` | Yes | VERIFIED |
| `.claude/skills/pdf-processing/scripts/check_fillable_fields.py` | Yes | VERIFIED |
| `.claude/skills/pdf-processing/scripts/check_bounding_boxes.py` | Yes | VERIFIED |
| `.claude/skills/pdf-processing/scripts/create_validation_image.py` | Yes | VERIFIED |

## Lint Rules for New/Modified Files

| File Path Pattern | Active Lint Rules |
|-------------------|-------------------|
| `lib/features/entries/presentation/widgets/*` | A3, A5, A8, A13, A18, A19, A20, A22, A23, D5 |
| `lib/features/entries/presentation/controllers/*` | A3, A5, A8, A13, A18, A19, A20, A22, A23, D5 |
| `lib/features/entries/presentation/screens/*` | A3, A5, A8, A13, A18, A19, A20, A21, A22, A23, D5 |
| `lib/features/pdf/services/*` | Global rules only (A1, A2, A7, A9-A12, A14, A17, D1-D4, D6, D7, D10, S2, S4, S8, T1, T6-T8) |
| `test/*` | No presentation lint rules apply |
