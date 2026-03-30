# Weather Constraints

**Feature**: Weather & Environmental Data
**Scope**: All code in `lib/features/weather/` and weather integration logic

---

## Hard Rules (Violations = Reject)

### WeatherService (Open-Meteo API)
- ✓ WeatherService calls Open-Meteo API (`https://api.open-meteo.com/v1/forecast`)
- ✓ Auto-fetch in EntryEditorScreen (guarded by `_isFetchingWeather` flag)
- ✓ WeatherCondition enum: sunny, cloudy, overcast, rainy, snow, windy
- ✗ No hardcoding API keys or endpoints
- ✗ No blocking entry creation due to missing weather (weather optional)

**Why**: Real-time weather data enhances entry context; graceful fallback if offline.

### Manual Override in Entries
- ✓ Inspector can optionally override or manually enter weather data
- ✓ Supported fields: temperature, conditions (dropdown from WeatherCondition enum), wind_speed (optional)
- ✓ Auto-fetched values pre-populate but are editable

**Why**: Offline-first; manual entry available when API is unreachable.

### Weather-Entry Association
- ✓ Entry can reference weather conditions (optional entry_weather record)
- ✓ Weather conditions immutable after entry SUBMITTED (snapshot at observation time)
- ✗ No changing weather data after entry marked SUBMITTED

**Why**: Audit trail; weather conditions must match work performed.

### No Persistence Requirement for Weather History
- ✗ No analytics/reporting on weather trends (future scope)
- ✓ Weather stored only when attached to entries (no standalone weather table)
- ✗ No syncing weather independently (synced as part of entry)

**Why**: Weather is contextual metadata for entries; not analyzed separately yet.

---

## Soft Guidelines (Violations = Discuss)

### Performance Targets
- Weather field load (if API integrated): < 1 second (with fallback to manual)
- Manual entry: < 100ms
- Weather condition render: < 100ms

### API Usage
- Recommend: Caching results (same conditions for 1+ hour likely)
- Recommend: Fallback to manual entry if API unavailable (offline scenarios)
- Recommend: Request permission for location (GPS) to enable auto-fetch

### Test Coverage
- Target: >= 85% for WeatherService and weather workflows

---

## Integration Points

- **Depends on**:
  - `entries` (weather conditions attached to entries)
  - `sync` (weather data synced as part of entry submission)

- **Required by**:
  - `entries` (optional weather association)
  - `dashboard` (current conditions display, optional)

---

## Performance Targets

- Weather field load: < 1 second (with fallback)
- Manual entry: < 100ms
- Render conditions: < 100ms

---

## Testing Requirements

- >= 85% test coverage for WeatherService and weather workflows
- Unit tests: API response parsing, manual weather entry validation, immutability after submission
- Integration tests: Create entry with weather→submit→verify immutable
- Edge cases: Missing optional fields (temperature blank, conditions not selected), API unavailable (offline fallback), corrupted weather data

---

## Reference

- **Architecture**: `docs/features/feature-weather-architecture.md`
- **Shared Rules**: `architecture-decisions/data-validation-rules.md`
- **Sync Integration**: `architecture-decisions/sync-constraints.md`
