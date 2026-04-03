# Pattern: Entry Header with Collapse/Expand

## How We Do It
The entry editor header in `_buildEntryHeader()` uses a `_headerExpanded` boolean to toggle visibility of detail rows (date, attribution, temperature). The header auto-expands when location or weather is null, and collapses once both are set. An `AnimatedSize` with `ClipRect` handles the animation. The collapsed state hides date, attribution, and temperature — which is the problem the spec targets.

## Exemplars

### _buildEntryHeader (entry_editor_screen.dart:926-1182)
Key structure:
```dart
Widget _buildEntryHeader(DailyEntry entry) {
  return Card(
    child: Column(children: [
      // Always visible: project name + expand/collapse chevron
      InkWell(
        onTap: () => setState(() => _headerExpanded = !_headerExpanded),
        child: Row(children: [
          Text('$_projectName — $_projectNumber'),
          AnimatedRotation(turns: _headerExpanded ? 0.5 : 0.0, child: Icon(Icons.expand_more)),
        ]),
      ),
      // Always visible: location chip + weather chip
      Row(children: [
        InkWell(onTap: _showLocationEditDialog, child: /*location*/),
        InkWell(onTap: _showWeatherEditDialog, child: /*weather chip*/),
      ]),
      // COLLAPSIBLE: date, attribution, temperature
      ClipRect(child: AnimatedSize(
        child: _headerExpanded
          ? Column(children: [/*date*/, /*attribution*/, /*temperature*/])
          : SizedBox.shrink(),
      )),
    ]),
  );
}
```

### Auto-expand logic (entry_editor_screen.dart)
```dart
bool _headerExpanded = true;  // line 92

// On load (line 331):
_headerExpanded = loadedEntry.locationId == null || loadedEntry.weather == null;

// On save (lines 501, 525):
_headerExpanded = updated.locationId == null || updated.weather == null;
```

## Reusable Methods

| Method | File:Line | Signature | When to Use |
|--------|-----------|-----------|-------------|
| _buildEntryHeader | entry_editor_screen.dart:926 | `Widget _buildEntryHeader(DailyEntry entry)` | Builds the full header card |
| _showLocationEditDialog | entry_editor_screen.dart | `void _showLocationEditDialog()` | Location picker |
| _showWeatherEditDialog | entry_editor_screen.dart | `void _showWeatherEditDialog()` | Weather condition picker |

## Imports
Already part of entry_editor_screen.dart — no additional imports needed.
