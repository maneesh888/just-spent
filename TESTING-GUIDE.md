# Just Spent - Testing Guide

## Overview
This document provides a comprehensive guide to running tests across iOS and Android platforms, including unit tests, UI tests, and integration tests.

## Table of Contents
1. [Testing Philosophy](#testing-philosophy)
2. [iOS Testing](#ios-testing)
3. [Android Testing](#android-testing)
4. [Test Comparison](#test-comparison)
5. [CI/CD Integration](#cicd-integration)

---

## Testing Philosophy

Both platforms follow the **Testing Pyramid** approach from `comprehensive-test-plan.md`:

```
         /\
        /E2E\        5% - End-to-End Tests
       /______\
      /        \
     /Integration\   20% - Integration Tests
    /______________\
   /                \
  /   Unit Tests     \  75% - Unit Tests
 /____________________\
```

### Coverage Goals
- **Unit Tests:** 85% code coverage
- **Integration Tests:** 70% API coverage
- **UI Tests:** Critical user paths
- **Performance Tests:** Voice processing <1.5s

### Testing Policy Updates

**Landscape Mode Testing** (Updated 2025-11-11):
- ✅ **Mobile Phones (iOS & Android)**: Portrait orientation only
- ✅ **Tablets (iOS & Android)**: Portrait and landscape orientations
- **Rationale**: Simplifies testing, reduces execution time, mobile landscape not a priority

---

## iOS Testing

### Test Structure

```
ios/JustSpent/
├── JustSpentTests/           # Unit Tests
│   ├── ExpenseRepositoryTests.swift
│   ├── VoiceCommandProcessorTests.swift
│   └── CurrencyFormatterTests.swift
└── JustSpentUITests/         # UI Tests
    └── MultiCurrencyUITests.swift
```

### Running iOS Tests

#### Command Line (xcodebuild)

```bash
# Navigate to iOS directory
cd ios/JustSpent

# Run ALL tests (unit + UI)
xcodebuild test \
  -project JustSpent.xcodeproj \
  -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run with detailed output
xcodebuild test \
  -project JustSpent.xcodeproj \
  -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | tee test_output.log

# Run specific test class
xcodebuild test \
  -project JustSpent.xcodeproj \
  -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:JustSpentTests/CurrencyFormatterTests

# Generate code coverage
xcodebuild test \
  -project JustSpent.xcodeproj \
  -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES \
  -resultBundlePath ./test_results
```

#### Xcode IDE

1. Open `JustSpent.xcodeproj` in Xcode
2. Press `⌘ + U` to run all tests
3. View results in the Test Navigator (⌘ + 6)
4. Right-click individual tests to run specific tests

### iOS Test Framework

**Unit Tests (XCTest):**
```swift
import XCTest
@testable import JustSpent

class CurrencyFormatterTests: XCTestCase {
    func testFormatAED_withSymbolAndGrouping_returnsCorrectFormat() {
        let result = CurrencyFormatter.shared.format(
            amount: Decimal(string: "1234.56")!,
            currency: .AED
        )
        XCTAssertEqual("د.إ 1,234.56", result)
    }
}
```

**UI Tests (XCUITest):**
```swift
import XCUITest

class MultiCurrencyUITests: XCTestCase {
    func testMultipleCurrencyTabs() {
        let app = XCUIApplication()
        app.launch()

        // Test interactions
        app.buttons["Add Expense"].tap()
        XCTAssert(app.staticTexts["No Expenses Yet"].exists)
    }
}
```

### iOS Test Characteristics

| Aspect | Details |
|--------|---------|
| **Process Model** | Separate process (black-box) |
| **Scope** | Full app launch required |
| **Speed** | Slower (full launch overhead) |
| **Access** | Accessibility APIs only |
| **Similar To** | Selenium, Playwright |
| **Best For** | True end-to-end flows |

---

## Android Testing

### Test Structure

```
android/app/src/
├── test/                     # Unit Tests (JVM)
│   └── java/com/justspent/app/
│       ├── CurrencyTests.kt
│       ├── data/repository/ExpenseRepositoryTest.kt
│       └── voice/VoiceCommandProcessorTest.kt
└── androidTest/              # Instrumentation Tests (Device)
    └── java/com/justspent/app/
        └── MultiCurrencyUITest.kt
```

### Running Android Tests

#### Using Test Script (Recommended)

```bash
# Navigate to Android directory
cd android

# Make script executable (first time only)
chmod +x test.sh

# Run unit tests only (fast, no device needed)
./test.sh unit

# Run UI tests (requires emulator/device)
./test.sh ui

# Run all tests
./test.sh all

# Watch mode (re-run on file changes)
./test.sh watch

# Clean build + test
./test.sh clean

# Run with coverage
./test.sh coverage
```

#### Using Gradle (Manual)

```bash
# Unit tests only
./gradlew testDebugUnitTest

# UI tests only (requires emulator)
./gradlew connectedDebugAndroidTest

# Both unit + UI
./gradlew test connectedAndroidTest

# Specific test class
./gradlew testDebugUnitTest --tests "*CurrencyTests*"

# With verbose output
./gradlew test --info

# With stacktrace
./gradlew test --stacktrace

# Clean + test
./gradlew clean test

# Generate HTML report
./gradlew test
# Report: android/app/build/reports/tests/testDebugUnitTest/index.html

# Code coverage
./gradlew testDebugUnitTest jacocoTestReport
# Report: android/app/build/reports/jacoco/test/html/index.html
```

#### Android Studio IDE

1. Right-click on test file/class → Run
2. View results in Run panel
3. Double-click failed tests to see details

### Android Test Frameworks

**Unit Tests (JUnit + Compose Testing):**
```kotlin
import org.junit.Test
import org.junit.Assert.*

class CurrencyTests {
    @Test
    fun formatAED_withSymbolAndGrouping_returnsCorrectFormat() {
        val result = CurrencyFormatter.format(
            amount = BigDecimal("1234.56"),
            currency = Currency.AED
        )
        assertEquals("د.إ 1,234.56", result)
    }
}
```

**UI Tests (Compose Testing - Component Level):**
```kotlin
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Rule
import org.junit.Test

class MultiCurrencyUITest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun testMultipleCurrencyTabs() {
        composeTestRule.setContent {
            MultiCurrencyTabbedScreen(/* ... */)
        }

        composeTestRule.onNodeWithText("USD").performClick()
        composeTestRule.onNodeWithText("No USD Expenses").assertIsDisplayed()
    }
}
```

### Android Test Characteristics

| Aspect | Details |
|--------|---------|
| **Process Model** | Same process (white-box) |
| **Scope** | Individual composables |
| **Speed** | Faster (no app launch) |
| **Access** | Direct compose tree access |
| **Similar To** | React Testing Library |
| **Best For** | Component isolation testing |

---

## Test Comparison

### iOS vs Android Testing Approaches

| Feature | iOS (XCUITest) | Android (Compose Test) |
|---------|----------------|------------------------|
| **Process** | Separate (2 processes) | Same (1 process) |
| **App Launch** | Full app every test | Only composable needed |
| **Element Finding** | Accessibility IDs | Test tags / semantics |
| **Speed** | Slower (~3-5s startup) | Faster (~100-500ms) |
| **Isolation** | Full app context | Component level |
| **Debugging** | Harder (separate process) | Easier (direct access) |
| **Best Use** | E2E flows | Component testing |

### When to Use Each Type

**iOS XCUITest (Full App):**
- ✅ Complete user journeys
- ✅ Cross-screen navigation
- ✅ System permission flows
- ✅ Voice assistant integration
- ❌ Simple component testing (use unit tests instead)

**Android Compose Test (Component):**
- ✅ Individual screen testing
- ✅ Component behavior
- ✅ UI state changes
- ✅ Fast iteration during development
- ❌ Cross-app interactions (use UIAutomator)

### Test Execution Speed Comparison

| Test Type | iOS | Android |
|-----------|-----|---------|
| **Unit Test** | ~100-200ms | ~50-150ms |
| **UI Test (Simple)** | ~3-5s | ~500ms-1s |
| **UI Test (Complex)** | ~10-30s | ~2-5s |
| **Full Suite** | ~5-10 min | ~2-5 min |

---

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Run Tests

on: [push, pull_request]

jobs:
  ios-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run iOS Tests
        working-directory: ios/JustSpent
        run: |
          xcodebuild test \
            -project JustSpent.xcodeproj \
            -scheme JustSpent \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -enableCodeCoverage YES

      - name: Upload Coverage
        uses: codecov/codecov-action@v3

  android-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'

      - name: Run Android Unit Tests
        working-directory: android
        run: ./gradlew testDebugUnitTest

      - name: Run Android UI Tests
        working-directory: android
        run: ./gradlew connectedDebugAndroidTest

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running tests before commit..."

# iOS Tests
cd ios/JustSpent
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet || exit 1

# Android Tests
cd ../../android
./gradlew testDebugUnitTest -q || exit 1

echo "✓ All tests passed!"
```

---

## Test Reports

### iOS Test Reports

**Location:**
- Xcode: Test Navigator (⌘ + 6)
- CLI: `DerivedData/Logs/Test/*.xcresult`
- HTML: Use `xchtmlreport` to generate

**Viewing Results:**
```bash
# Generate HTML report (requires xchtmlreport)
brew install xchtmlreport
xchtmlreport -r test_results.xcresult
```

### Android Test Reports

**Locations:**
- **Unit Tests:** `android/app/build/reports/tests/testDebugUnitTest/index.html`
- **UI Tests:** `android/app/build/reports/androidTests/connected/index.html`
- **Coverage:** `android/app/build/reports/jacoco/test/html/index.html`

**Viewing:**
```bash
# Open unit test report
open android/app/build/reports/tests/testDebugUnitTest/index.html

# Open coverage report
open android/app/build/reports/jacoco/test/html/index.html
```

---

## Troubleshooting

### iOS Issues

**Simulator not found:**
```bash
# List available simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 16"
```

**Tests timing out:**
- Increase timeout in test settings
- Check if simulator is responsive
- Try different simulator model

### Android Issues

**Emulator not detected:**
```bash
# List connected devices
adb devices

# Start emulator
emulator -avd Pixel_6_API_34
```

**Compilation errors:**
- Ensure JDK 17 is installed: `java -version`
- Clean build: `./gradlew clean`
- Invalidate Android Studio caches

---

## Best Practices

### General
- ✅ Run unit tests frequently during development
- ✅ Run UI tests before commits
- ✅ Maintain 85%+ code coverage
- ✅ Write tests before fixing bugs (TDD)
- ✅ Keep tests fast and isolated

### iOS Specific
- ✅ Use accessibility identifiers for UI elements
- ✅ Test on multiple device sizes
- ✅ Handle system alerts in UI tests
- ✅ Use XCTAssertions effectively

### Android Specific
- ✅ Use test tags for compose elements
- ✅ Mock dependencies properly
- ✅ Use Hilt for dependency injection in tests
- ✅ Separate unit tests from instrumentation tests

---

## Quick Reference

### iOS Commands
```bash
# Run all tests
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test
xcodebuild test -only-testing:JustSpentTests/CurrencyFormatterTests

# With coverage
xcodebuild test -enableCodeCoverage YES -resultBundlePath ./results
```

### Android Commands
```bash
# Unit tests
./test.sh unit

# UI tests
./test.sh ui

# All tests
./test.sh all

# Specific test
./gradlew testDebugUnitTest --tests "*CurrencyTests*"
```

---

**Last Updated:** January 2025
**Maintained By:** Development Team
**Related Docs:** `comprehensive-test-plan.md`, `CLAUDE.md`
