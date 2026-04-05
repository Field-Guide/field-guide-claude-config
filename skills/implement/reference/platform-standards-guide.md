# Platform Standards — Procedure Guide

> Loaded on-demand by workers. For constraints and invariants, see `.claude/rules/platform-standards.md`

## Problem Statement

Integration tests were crashing after 20 tests due to memory exhaustion on Android 13+, outdated SDK versions, insufficient heap allocation, and missing test isolation.

## Android Configuration

### SDK Versions (`android/app/build.gradle.kts`)
```kotlin
compileSdk = 36  // Android 16 - Latest stable for 2026
minSdk = 31      // Android 12 - Required by flusseract (Tesseract OCR FFI)
targetSdk = 36   // Required for Play Store submissions
```

### Test Memory Settings
```kotlin
// In defaultConfig:
testInstrumentationRunnerArguments["maxTestsPerDevice"] = "5"
testInstrumentationRunnerArguments["testTimeoutInMs"] = "600000"

// In testOptions:
testOptions {
    execution = "ANDROIDX_TEST_ORCHESTRATOR"
    unitTests {
        isIncludeAndroidResources = true
        isReturnDefaultValues = true
    }
    animationsDisabled = true
}
```

### Test Dependencies
```kotlin
androidTestUtil("androidx.test:orchestrator:1.6.1")
androidTestImplementation("androidx.test:runner:1.6.2")
androidTestImplementation("androidx.test:rules:1.6.1")
```

### Gradle Memory (`android/gradle.properties`)
```properties
org.gradle.jvmargs=-Xmx12G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+UseG1GC
org.gradle.workers.max=4
android.enableJetifier=false
```

## iOS Configuration

### Minimum iOS Version
Files: `ios/Flutter/AppFrameworkInfo.plist`, `ios/Runner.xcodeproj/project.pbxproj` (3 occurrences)
```xml
<key>MinimumOSVersion</key>
<string>13.0</string>
```

## Files Modified

| File | Changes |
|------|---------|
| `android/app/build.gradle.kts` | SDK versions, test options, dependencies |
| `android/gradle.properties` | JVM heap, workers, G1GC |
| `ios/Flutter/AppFrameworkInfo.plist` | iOS 13.0 minimum |
| `ios/Runner.xcodeproj/project.pbxproj` | iOS 13.0 deployment target (3x) |

## Verification
```bash
cd android && ./gradlew --version  # Gradle 8.13
./gradlew help --warning-mode=all  # Build config valid
pwsh -Command "flutter analyze"    # No new errors
```

## Rollback Plan
Revert: Android compileSdk/targetSdk to 33, minSdk to 21, Gradle heap to 8G, Test Orchestrator to 1.4.2.

## Next Steps
- `testInstrumentationRunner` still references `pl.leancode.patrol.PatrolJUnitRunner` — update to `androidx.test.runner.AndroidJUnitRunner` when integration tests revisited.
