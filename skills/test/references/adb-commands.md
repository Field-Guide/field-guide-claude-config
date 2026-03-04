# ADB Command Reference for Test Agents

Quick reference for ADB commands used by test-wave-agent during automated testing. All commands assume a single USB-connected Android device.

## CRITICAL: Platform Workarounds

These workarounds are MANDATORY. Using the standard commands will FAIL.

### Android 15: screencap broken
`adb shell screencap -p /sdcard/file.png` **FAILS** on Android 15. Use pipe instead:
```bash
MSYS_NO_PATHCONV=1 adb exec-out screencap -p > ./local_file.png
```

### Git Bash: /sdcard/ path mangling
Git Bash rewrites `/sdcard/` to `C:/Program Files/Git/sdcard/`. **ALL** ADB commands with `/sdcard/` paths MUST be prefixed:
```bash
MSYS_NO_PATHCONV=1 adb shell uiautomator dump /sdcard/ui_dump.xml
MSYS_NO_PATHCONV=1 adb pull /sdcard/ui_dump.xml ./ui_dump.xml
```

### Samsung: ENTER key triggers screenshot toolbar
`KEYCODE_ENTER` activates the Samsung scroll-capture toolbar. **NEVER** use `adb shell input keyevent KEYCODE_ENTER`. Tap buttons directly instead.

### Flutter: No resource-id in UIAutomator
Flutter `Key('name')` does NOT produce `resource-id` in UIAutomator XML on this device. Use `content-desc` (from Semantics labels) or `text` attributes for element finding.

---

## Device Management

### Check connected devices
```bash
adb devices -l
```
Expected output: A line with a device serial and `device` status. If `unauthorized`, the device needs USB debugging approval.

### Get device info
```bash
adb shell getprop ro.product.model          # Device model
adb shell getprop ro.build.version.release   # Android version
adb shell getprop ro.build.version.sdk       # SDK level
```

## App Installation & Launch

### Install APK
```bash
adb install -r path/to/app.apk
```
- `-r` replaces existing installation
- `-t` allows test-signed APKs (add if install fails with certificate error)

### Launch app
```bash
adb shell am start -n com.fieldguideapp.inspector/com.fieldguideapp.inspector.MainActivity
```

### Force stop app
```bash
adb shell am force-stop com.fieldguideapp.inspector
```

### Check if app is running
```bash
adb shell pidof com.fieldguideapp.inspector
```
Returns PID if running, empty if not.

### Clear app data (full reset)
```bash
adb shell pm clear com.fieldguideapp.inspector
```
Warning: This clears all local data including SQLite database.

## UI Interaction

### Tap at coordinates
```bash
adb shell input tap X Y
```
Where X,Y are pixel coordinates. Get coordinates from UIAutomator XML element bounds.

### Long press at coordinates
```bash
adb shell input swipe X Y X Y 1000
```
Same start and end point with 1000ms duration simulates long press.

### Type text
```bash
adb shell input text "hello%sworld"
```
- `%s` = space (spaces must be encoded)
- Special characters need escaping
- For complex text, use `adb shell input keyevent` sequences instead

### Key events
```bash
adb shell input keyevent KEYCODE_BACK        # Back button
adb shell input keyevent KEYCODE_HOME        # Home button
adb shell input keyevent KEYCODE_TAB         # Tab
adb shell input keyevent KEYCODE_DEL         # Backspace/Delete
adb shell input keyevent KEYCODE_ESCAPE      # Escape
```
**WARNING**: Do NOT use `KEYCODE_ENTER` — triggers Samsung screenshot toolbar.

### Scroll / Swipe
```bash
# Swipe up (scroll down)
adb shell input swipe 540 1500 540 500 300

# Swipe down (scroll up)
adb shell input swipe 540 500 540 1500 300

# Swipe left
adb shell input swipe 900 1000 100 1000 300

# Swipe right
adb shell input swipe 100 1000 900 1000 300
```
Format: `input swipe startX startY endX endY durationMs`

### Clear a text field
```bash
# Triple-tap to select all, then type replacement
adb shell input tap X Y && sleep 0.1 && adb shell input tap X Y && sleep 0.1 && adb shell input tap X Y
adb shell input text "replacement"
```

## Screenshots

### Capture screenshot (Android 15 safe)
```bash
MSYS_NO_PATHCONV=1 adb exec-out screencap -p > ./screenshots/step_1.png
```
**DO NOT** use `adb shell screencap -p /sdcard/...` — it fails on Android 15.

## UIAutomator XML Dump

### Dump current UI hierarchy
```bash
MSYS_NO_PATHCONV=1 adb shell uiautomator dump /sdcard/ui_dump.xml
MSYS_NO_PATHCONV=1 adb pull /sdcard/ui_dump.xml ./ui_dump.xml
```

### Important notes
- UIAutomator dump takes 1-3 seconds — wait for animations to settle first
- The dump may fail if a system dialog is covering the app
- Retry once after a 2-second wait if the dump fails
- The dump file is overwritten each time — pull before taking the next dump

## Log Collection (MANDATORY)

### Check logcat after every interaction
```bash
adb logcat -d -t 5 *:W 2>/dev/null | tail -30
```
Run this AFTER EVERY ADB interaction. Look for Flutter errors, network failures, snackbar messages.

### Full log collection for a flow
```bash
adb logcat -d -t 60 *:W > ./screenshots/{flow}-warnings.log 2>/dev/null
adb logcat -d -s flutter > ./screenshots/{flow}-flutter.log 2>/dev/null
```

### Clear logcat buffer (do before each flow)
```bash
adb logcat -c
```

### What to look for in logs
- `E/flutter` — Flutter framework errors
- `Exception` / `Error` — Dart exceptions
- `SocketException` / `TimeoutException` — Network failures
- `HandshakeException` — TLS/SSL issues
- `UNIQUE constraint failed` — Database conflicts
- `SnackBar` — May indicate error messages shown to user

## Connectivity Check

### Check internet connectivity
```bash
adb shell ping -c 1 -W 3 google.com
```
Exit code 0 = connected, non-zero = no connectivity.

## Screen State

### Wake screen
```bash
adb shell input keyevent KEYCODE_WAKEUP
```

### Unlock screen (swipe up)
```bash
adb shell input swipe 540 1800 540 800 300
```

## Common Patterns for Test Agents

### Wait for element pattern
```
1. MSYS_NO_PATHCONV=1 adb shell uiautomator dump /sdcard/ui_dump.xml
2. MSYS_NO_PATHCONV=1 adb pull /sdcard/ui_dump.xml ./ui_dump.xml
3. Parse XML for target element (by content-desc or text, NOT resource-id)
4. If not found: sleep 2s, retry (max 3 retries)
5. If found: extract bounds, compute center, tap
```

### Text input pattern
```
1. Tap the text field (from UIAutomator coordinates)
2. Sleep 500ms (wait for keyboard)
3. Clear existing text if needed
4. adb shell input text "encoded%stext"
5. Sleep 500ms
6. Check logcat for errors
7. Optionally dismiss keyboard: adb shell input keyevent KEYCODE_ESCAPE
```

### Screenshot + logcat verification pattern
```
1. Sleep 1-2s (wait for UI to settle)
2. MSYS_NO_PATHCONV=1 adb exec-out screencap -p > ./screenshots/flow_step_N.png
3. adb logcat -d -t 5 *:W 2>/dev/null | tail -30
4. Read screenshot with vision for visual verification
5. Check logcat output for errors
```

### App crash detection pattern
```
1. adb shell pidof com.fieldguideapp.inspector
2. If empty: app crashed
3. Check logcat for crash reason: adb logcat -d -t 30 *:E | tail -50
4. Attempt relaunch: adb shell am start -n ...
5. If relaunch fails after 3 attempts: mark flow as FAIL
```
