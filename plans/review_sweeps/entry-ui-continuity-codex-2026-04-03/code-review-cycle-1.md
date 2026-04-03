# Code Review — Cycle 1

**Verdict: REJECT**

## Critical Issues

**C1. `AppDialog.show` uses wrong parameter `contentBuilder:`** (Phase 2.3)
- `AppDialog.show` requires `content: Widget`, not `contentBuilder:`. Fix: Use `content: _NewContractorForm()`.

**C2. `Contractor` constructor uses `isPrime:` — field does not exist** (Phase 2.3)
- `Contractor` requires `type: ContractorType`, not `isPrime: bool`. `isPrime` is a read-only getter.
- Fix: `type: result.isPrime ? ContractorType.prime : ContractorType.sub`

**C3. `_editingController.setWeather()` does not exist** (Phase 4.2.1)
- `EntryEditingController` has no `setWeather` method. Weather is set via `entry.copyWith(weather: ...)` + `entryProvider.updateEntry(updated)`.

**C4. Type mismatch: `WeatherData.condition` is `String`, `DailyEntry.weather` is `WeatherCondition?`** (Phase 4.2.1)
- Need to convert: `WeatherCondition.values.byName(weatherData.condition)`. Temps are non-nullable int, not nullable.

**C5. `autoWeatherEnabled` does not exist on `AppConfigProvider`** (Phase 4.2.1)
- Property doesn't exist. Either add it, remove the gate, or default to false.

## Major Issues

**M1. Calculator navigation uses `Navigator.push` instead of go_router** (Phase 5.1.2)
- Existing code uses `context.push<QuantityCalculatorResult>('/quantity-calculator/${_entry!.id}')`.

**M2. Calendar entry pill uses raw path push** (Phase 3.1.2)
- Existing code uses `context.pushNamed('report', pathParameters: {'entryId': entry.id})`.

**M3. Weather auto-fetch bypasses established entry-update pattern** (Phase 4.2.1)
- Should use `copyWith` + provider pattern, not `_editingController` fields.

**M4. `_buildEntryHeader` code block uses hardcoded pixel values** (Phase 4.1.1)
- Uses `16`, `8`, `4` instead of `DesignConstants.space4`, `space2`, `space1`.

## Minor Issues

- m1: `PdfPreview` has its own action bar — add `allowSharing: false, allowPrinting: false`.
- m2: Missing imports for SnackBarHelper, Logger in EntryPdfPreviewScreen.
- m3: TestingKeys.calendarEntryPill needs forwarding in TestingKeys class.
