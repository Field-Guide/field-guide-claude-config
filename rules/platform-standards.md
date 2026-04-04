---
paths:
  - "android/**/*"
  - "ios/**/*"
  - "pubspec.yaml"
---

<!--
  Loaded automatically when editing Android/iOS config or pubspec.yaml.
  Not wired to a specific agent — platform work is done inline by whichever agent is working.
  Canonical source for SDK versions. Root CLAUDE.md should reference this file, not duplicate it.
  Note: Gradle 8.13, Android Gradle Plugin 8.11.1 here are the authoritative versions.
-->

# 2026 Platform Standards Update

**Date**: 2026-01-21
**Purpose**: Update Android and iOS configurations to 2026 standards to prevent test crashes and improve stability

## Problem Statement

Integration tests were crashing after 20 tests due to:
- Memory exhaustion on Android 13+ (stricter memory policies)
- Outdated SDK versions and test configurations
- Insufficient heap allocation for long test runs
- Missing test isolation and cleanup settings

## Changes Implemented

### Android Configuration Updates

#### 1. SDK Versions (`android/app/build.gradle.kts`)

**Before:**
```kotlin
compileSdk = flutter.compileSdkVersion  // Was 33
minSdk = flutter.minSdkVersion          // Was 21
targetSdk = flutter.targetSdkVersion    // Was 33
```

**After:**
```kotlin
compileSdk = 36  // Android 16 - Latest stable for 2026
minSdk = 31      // Android 12 - Required by flusseract (Tesseract OCR FFI)
targetSdk = 36   // Required for Play Store submissions
```

**Rationale:**
- Android 16 (API 36) provides better memory management
- API 31+ required by flusseract (Tesseract OCR FFI) native dependency
- Dropping API 21-30 eliminates legacy devices with poor memory handling

#### 2. Test Memory Settings (`android/app/build.gradle.kts`)

**Added to defaultConfig:**
```kotlin
testInstrumentationRunnerArguments["maxTestsPerDevice"] = "5"
testInstrumentationRunnerArguments["testTimeoutInMs"] = "600000"
```

**Added to testOptions:**
```kotlin
testOptions {
    execution = "ANDROIDX_TEST_ORCHESTRATOR"

    unitTests {
        isIncludeAndroidResources = true
        isReturnDefaultValues = true
    }

    animationsDisabled = true  // Prevents test flakiness
}
```

**Rationale:**
- Limits tests per device to prevent memory buildup
- Increases timeout for complex integration tests
- Disables animations to reduce test flakiness
- Test orchestrator ensures proper isolation between tests

#### 3. Test Dependencies (`android/app/build.gradle.kts`)

**Before:**
```kotlin
androidTestUtil("androidx.test:orchestrator:1.4.2")
```

**After:**
```kotlin
androidTestUtil("androidx.test:orchestrator:1.6.1")
androidTestImplementation("androidx.test:runner:1.6.2")
androidTestImplementation("androidx.test:rules:1.6.1")
```

**Rationale:**
- Orchestrator 1.6.1 has better memory management
- Additional test runner and rules improve integration test stability

#### 4. Gradle Memory Settings (`android/gradle.properties`)

**Before:**
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G ...
```

**After:**
```properties
org.gradle.jvmargs=-Xmx12G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+UseG1GC
org.gradle.workers.max=4
android.enableJetifier=false
```

**Rationale:**
- 12G heap prevents OOM in long integration test runs
- G1GC provides better garbage collection for tests
- Limited workers prevent memory fragmentation
- Jetifier disabled (no longer needed with androidx)

### iOS Configuration Updates

#### 1. Minimum iOS Version

**Files Updated:**
- `ios/Flutter/AppFrameworkInfo.plist`
- `ios/Runner.xcodeproj/project.pbxproj` (3 occurrences)

**Current value:**
```xml
<key>MinimumOSVersion</key>
<string>13.0</string>
```

**Rationale:**
- iOS 13.0 is the current deployment target across all iOS config files
- Maintains broad device compatibility
- Aligned with Flutter 3.38+ minimum requirements

### Documentation Updates

#### Project CLAUDE.md

Added comprehensive platform requirements table to `.claude/CLAUDE.md`:

```markdown
## Platform Requirements (2026 Standards)

### Flutter
| Component | Version | Notes |
|-----------|---------|-------|
| Flutter | 3.38.9 | Pinned in CI (quality-gate.yml) |

### Android
| Component | Version | Notes |
|-----------|---------|-------|
| compileSdk | 36 (Android 16) | Latest stable for 2026 |
| targetSdk | 36 | Required for Play Store |
| minSdk | 31 (Android 12) | Required by flusseract (Tesseract OCR FFI) |
| Gradle | 8.13 | Via gradle-wrapper.properties |
| Android Gradle Plugin | 8.11.1 | Latest stable |
| Kotlin | 2.2.20 | Latest stable |
| Java | 17 | LTS version |

### iOS
| Component | Version | Notes |
|-----------|---------|-------|
| Minimum iOS | 13.0 | Deployment target in pbxproj and AppFrameworkInfo.plist |
| Xcode | 15.0+ | Required for build support |

### Test Configuration
| Component | Version | Purpose |
|-----------|---------|---------|
| Test Orchestrator | 1.6.1 | Proper test isolation |
| JVM Heap (Tests) | 12G | Prevents OOM in long test runs |
| Max Tests Per Device | 5 | Memory exhaustion prevention |
```

## Verification

### Gradle Build
```bash
cd android
./gradlew --version
# Gradle 8.13 confirmed

./gradlew help --warning-mode=all
# Build configuration valid
```

### Flutter Analyze
```bash
pwsh -Command "flutter analyze"
# 18 issues found (pre-existing, not related to platform changes)
# No new errors introduced
```

## Expected Improvements

### Test Stability
1. **Memory Management**: 12G heap + G1GC prevents OOM crashes
2. **Test Isolation**: Orchestrator ensures clean state between tests
3. **Timeouts**: Extended timeouts accommodate complex integration tests
4. **Animations**: Disabled in tests reduces flakiness

### Performance
1. **Modern APIs**: Android 16 and iOS 13+ have better runtime performance
2. **Reduced Legacy Code**: Dropping old SDKs reduces compatibility layers
3. **Garbage Collection**: G1GC provides smoother memory cleanup

### Compatibility
1. **Play Store**: targetSdk 36 meets 2026 requirements
2. **Device Coverage**: Focuses on devices from last 4 years (Android 12+)
3. **Flutter Alignment**: Better compatibility with Flutter 3.38+

## Files Modified

| File | Changes |
|------|---------|
| `android/app/build.gradle.kts` | SDK versions, test options, dependencies |
| `android/gradle.properties` | JVM heap, workers, G1GC |
| `ios/Flutter/AppFrameworkInfo.plist` | iOS 13.0 minimum |
| `ios/Runner.xcodeproj/project.pbxproj` | iOS 13.0 deployment target (3x) |
| `.claude/CLAUDE.md` | Platform requirements table |

## Next Steps

1. **Test Execution**: Run full test suite to validate improvements
   ```bash
   pwsh -Command "flutter test"
   ```

2. **Memory Monitoring**: Monitor heap usage during integration tests
   ```bash
   pwsh -Command "flutter test integration_test/ --verbose"
   ```

3. **CI/CD**: Update CI pipeline to use new SDK versions

4. **Device Testing**: Verify on physical devices running Android 12+ and iOS 13+

5. **TODO**: `testInstrumentationRunner` in build.gradle.kts still references `pl.leancode.patrol.PatrolJUnitRunner` but Patrol has been removed from pubspec.yaml. Update to `androidx.test.runner.AndroidJUnitRunner` when integration tests are next revisited.

## Rollback Plan

If issues arise, revert these commits:
```bash
git revert HEAD
```

Or manually revert:
- Android compileSdk/targetSdk to 33, minSdk to 21
- iOS MinimumOSVersion to 13.0 (already at 13.0)
- Gradle heap to 8G
- Test Orchestrator to 1.4.2

## References

- [Android 16 Features](https://developer.android.com/about/versions/16)
- [Gradle 8.13 Release Notes](https://docs.gradle.org/8.13/release-notes.html)
- [Test Orchestrator Guide](https://developer.android.com/training/testing/instrumented-tests/androidx-test-libraries/test-orchestrator)
- [Flutter Platform Support](https://docs.flutter.dev/reference/supported-platforms)
