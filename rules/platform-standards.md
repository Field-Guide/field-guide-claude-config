---
paths:
  - "android/**/*"
  - "ios/**/*"
  - "pubspec.yaml"
---

<!--
  Loaded automatically when editing Android/iOS config or pubspec.yaml.
  Canonical source for SDK versions. Root CLAUDE.md references this file, not duplicates.
  Gradle 8.13, Android Gradle Plugin 8.11.1 are authoritative.
-->

# Platform Standards (2026)

## Version Matrix

| Component | Version | Notes |
|-----------|---------|-------|
| compileSdk | 36 (Android 16) | Latest stable |
| targetSdk | 36 | Required for Play Store |
| minSdk | 31 (Android 12) | Required by flusseract (Tesseract OCR FFI) |
| Gradle | 8.13 | Via gradle-wrapper.properties |
| Android Gradle Plugin | 8.11.1 | Latest stable |
| Kotlin | 2.2.20 | Latest stable |
| Java | 17 | LTS |
| iOS deployment target | 13.0 | In pbxproj (3 occurrences) + AppFrameworkInfo.plist |
| Test Orchestrator | 1.6.1 | Proper test isolation |
| JVM Heap (Tests) | 12G | Prevents OOM in long test runs |

## Gotchas

- **PRAGMAs via `rawQuery`** — Android API 36 rejects PRAGMA via `execute()`.
- **`testInstrumentationRunner`** still references `pl.leancode.patrol.PatrolJUnitRunner` — needs update to `androidx.test.runner.AndroidJUnitRunner` when integration tests are revisited.
- **NDK 28.2** removed `gold` linker — fix: `-DANDROID_LD=lld` in CMake toolchain args.

> For configuration details, migration history, and rollback plan, see `.claude/skills/implement/references/platform-standards-guide.md`
