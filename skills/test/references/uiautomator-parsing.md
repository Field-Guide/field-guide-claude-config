# UIAutomator XML Parsing Reference

Guide for test-wave-agent on parsing UIAutomator XML dumps to find and interact with UI elements.

## XML Structure

UIAutomator dumps produce an XML hierarchy representing the current view tree. Each node is a UI element.

### Sample node
```xml
<node index="0"
      text="Sign In"
      resource-id="com.fieldguideapp.inspector:id/login_sign_in_button"
      class="android.widget.Button"
      package="com.fieldguideapp.inspector"
      content-desc=""
      checkable="false"
      checked="false"
      clickable="true"
      enabled="true"
      focusable="true"
      focused="false"
      scrollable="false"
      long-clickable="false"
      password="false"
      selected="false"
      bounds="[72,1680][1008,1776]" />
```

### Key attributes

| Attribute | Purpose | Use for |
|-----------|---------|---------|
| `resource-id` | Widget key mapped to Android resource ID | Primary element finding |
| `text` | Visible text content | Fallback element finding |
| `content-desc` | Accessibility description | Secondary fallback |
| `bounds` | Screen coordinates `[left,top][right,bottom]` | Computing tap coordinates |
| `clickable` | Whether element accepts taps | Filtering interactive elements |
| `enabled` | Whether element is active | Checking if button is actionable |
| `class` | Android widget class | Identifying element type |
| `scrollable` | Whether element can scroll | Finding scroll containers |
| `checked` | Checkbox/toggle state | Verifying toggle states |
| `focused` | Whether element has input focus | Verifying text field selection |

## Element Finding Strategy

### Priority 1: resource-id (Most Reliable)

Flutter's `Key('some_key')` maps to Android resource-id as `com.fieldguideapp.inspector:id/some_key`.

**Search pattern**:
```
resource-id="com.fieldguideapp.inspector:id/login_email_field"
```

**How Flutter Keys map**:
- Flutter `Key('login_email_field')` becomes resource-id `com.fieldguideapp.inspector:id/login_email_field`
- The prefix is always `com.fieldguideapp.inspector:id/`
- The suffix matches the Key string exactly

**Finding by resource-id in XML**:
Look for nodes where `resource-id` contains the key name:
```
resource-id="com.fieldguideapp.inspector:id/{key_name}"
```

### Priority 2: text content (Fallback)

When resource-id is not available, search by visible text:
```
text="Sign In"
text="Save Draft"
text="Submit"
```

**Tips**:
- Text matching is case-sensitive
- Look for both `text` and `content-desc` attributes
- Button text may change with app state (e.g., "Save" vs "Update")

### Priority 3: Vision-guided coordinates (Last Resort)

When neither resource-id nor text works:
1. Take a screenshot
2. Pass to Claude vision: "Where is the [element description] on this screen?"
3. Claude estimates pixel coordinates
4. Use those coordinates for `adb shell input tap X Y`

**Warning**: This method is least reliable. Coordinates may vary by device resolution and orientation.

## Bounds Parsing

### Format
```
bounds="[left,top][right,bottom]"
```

Example: `bounds="[72,1680][1008,1776]"`
- Left: 72, Top: 1680
- Right: 1008, Bottom: 1776

### Computing center tap point

```
centerX = (left + right) / 2
centerY = (top + bottom) / 2
```

Example:
```
centerX = (72 + 1008) / 2 = 540
centerY = (1680 + 1776) / 2 = 1728
```

Tap command: `adb shell input tap 540 1728`

### Parsing bounds from XML text

The bounds string follows the regex pattern:
```
\[(\d+),(\d+)\]\[(\d+),(\d+)\]
```

Groups: left, top, right, bottom.

## Common Patterns

### Finding a text field and entering text

```
1. Search XML for resource-id matching the field key
2. Extract bounds
3. Compute center coordinates
4. Tap to focus: adb shell input tap centerX centerY
5. Wait 500ms for keyboard
6. Enter text: adb shell input text "encoded%stext"
```

### Finding a button and tapping it

```
1. Search XML for resource-id matching the button key
2. Verify enabled="true"
3. Extract bounds, compute center
4. Tap: adb shell input tap centerX centerY
5. Wait 1-2s for action to complete
```

### Checking if an element exists

```
1. Dump UIAutomator XML
2. Search for resource-id or text
3. If found: element exists (return true + bounds)
4. If not found: element does not exist (return false)
```

### Verifying element state

```
1. Find element by resource-id
2. Check attributes:
   - enabled="true" → button is clickable
   - checked="true" → checkbox/toggle is on
   - text="Expected Text" → content matches
   - focused="true" → field has input focus
```

### Scrolling to find an element

```
1. Dump XML, search for element
2. If not found:
   a. Find the nearest scrollable container (scrollable="true")
   b. Get container bounds
   c. Swipe up within container: adb shell input swipe centerX bottom centerX top 300
   d. Wait 1s
   e. Dump XML again, search for element
   f. Repeat up to 5 times
3. If still not found after scrolling: element not present
```

## Flutter-Specific Considerations

### Key propagation

Not all Flutter widgets propagate their `Key` to the native Android view tree. The Key must be set on a widget that renders to a native view:

- **Works**: Keys on `Scaffold`, `ElevatedButton`, `TextField`, `Text`, `FloatingActionButton`, `ListTile`, `Card`
- **May not work**: Keys on `Padding`, `Center`, `Align`, `SizedBox` (these may not produce separate native nodes)

### Semantics and content-desc

Flutter's `Semantics` widget populates `content-desc`. Some elements may have `content-desc` but no `resource-id`:

```xml
<node content-desc="Settings" resource-id="" ... />
```

Use `content-desc` as a fallback when `resource-id` is empty.

### Dropdown menus

Flutter dropdown menus create an overlay (popup) that appears as a separate node tree in UIAutomator. When a dropdown is open:

1. The original dropdown button is still in the tree
2. A new overlay container appears with menu items
3. Menu items may have `text` attributes but not always `resource-id`
4. Look for the overlay by searching for nodes with the expected option text

### Bottom sheets

Similar to dropdowns, bottom sheets create overlay nodes:

1. The main content tree is still present
2. A `BottomSheet` container appears in the tree
3. Elements within the bottom sheet have their own resource-ids
4. The sheet may be scrollable

### SnackBars and Dialogs

- **SnackBars**: Appear briefly, may not be caught by UIAutomator dump timing
- **Dialogs**: Create overlay nodes, findable by resource-id or button text
- **Loading indicators**: CircularProgressIndicator may appear as a generic node without useful attributes

## Device Resolution Considerations

Different devices have different screen resolutions. Coordinates from UIAutomator bounds are in actual pixels.

| Device | Resolution | Density |
|--------|-----------|---------|
| Pixel 7a | 1080x2400 | 420dpi |
| Pixel 6 | 1080x2400 | 420dpi |
| Samsung S23 | 1080x2340 | 425dpi |

The test agent should always read bounds from the current XML dump rather than hardcoding coordinates.

## Troubleshooting

### UIAutomator dump fails
- **Cause**: System dialog covering the app, or app is not in foreground
- **Fix**: Dismiss dialog (`adb shell input keyevent KEYCODE_BACK`), wait 2s, retry

### Element has resource-id but wrong format
- **Cause**: Flutter key didn't propagate to native view
- **Fix**: Try searching by `text` or `content-desc` instead

### Element not found after navigation
- **Cause**: Screen transition animation still in progress
- **Fix**: Wait 2-3 seconds after navigation, then dump XML

### Multiple elements with same text
- **Cause**: Common labels like "Save", "Cancel", "OK"
- **Fix**: Prefer resource-id. If using text, also filter by class or position (use bounds to pick the right one)

### Keyboard covers elements
- **Cause**: Soft keyboard is open, covering bottom of screen
- **Fix**: Dismiss keyboard (`adb shell input keyevent KEYCODE_ESCAPE` or `KEYCODE_BACK`), then interact with the covered element
