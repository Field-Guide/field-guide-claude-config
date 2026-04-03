# Pattern: Weather Auto-Fetch

## How We Do It
`WeatherService` provides `fetchWeatherForCurrentLocation(DateTime date)` which gets GPS position then fetches weather. `WeatherProvider` wraps this as a ChangeNotifier. The old `EntryBasicsSection` widget (dead code, 0 importers) had an auto-fetch button wired to `onAutoFetchWeather` callback. The current `entry_editor_screen.dart` does NOT use either — weather is manual-edit only via `ReportWeatherEditDialog`.

## Exemplars

### WeatherService.fetchWeatherForCurrentLocation (weather_service.dart:190-196)
```dart
Future<WeatherData?> fetchWeatherForCurrentLocation(DateTime date) async {
  final position = await getCurrentLocation();
  if (position == null) return null;
  return fetchWeather(position.latitude, position.longitude, date);
}
```

### WeatherProvider.fetchWeather (weather_provider.dart:23-49)
```dart
Future<void> fetchWeather({
  required double latitude,
  required double longitude,
  DateTime? date,
}) async {
  _isLoading = true; _error = null; notifyListeners();
  try {
    _currentWeather = await _weatherService.fetchWeather(latitude, longitude, date ?? DateTime.now());
  } catch (e, stackTrace) {
    _error = e.toString();
    Logger.ui('Failed to fetch weather: $e', data: {...});
  } finally {
    _isLoading = false; notifyListeners();
  }
}
```

### EntryBasicsSection (DEAD CODE — entry_basics_section.dart:11-209)
Has the auto-fetch UI:
```dart
OutlinedButton.icon(
  key: TestingKeys.weatherFetchButton,
  onPressed: isFetchingWeather ? null : onAutoFetchWeather,
  icon: isFetchingWeather
      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
      : Icon(Icons.refresh),
  label: Text(isFetchingWeather ? 'Fetching...' : 'Auto-fetch Weather'),
)
```

### Current Entry Header Weather (entry_editor_screen.dart:926-1182)
Manual-only: tappable weather chip opens `_showWeatherEditDialog()`. No auto-fetch path exists.

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| WeatherService.fetchWeatherForCurrentLocation | weather_service.dart:190 | `Future<WeatherData?> fetchWeatherForCurrentLocation(DateTime date)` | Auto-fetch weather for GPS location |
| WeatherService.fetchWeather | weather_service.dart:111 | `Future<WeatherData?> fetchWeather(double lat, double lon, DateTime date)` | Fetch weather for known coordinates |
| WeatherProvider.fetchWeather | weather_provider.dart:23 | `Future<void> fetchWeather({latitude, longitude, date?})` | Provider-managed weather fetch |

## Imports
```dart
import 'package:construction_inspector/features/weather/services/weather_service.dart';
import 'package:construction_inspector/features/weather/presentation/providers/weather_provider.dart';
```
