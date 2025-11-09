# Localization Testing Guide

## Overview

This guide explains the **single source of truth approach** for cross-platform localization testing in Just Spent. Both iOS and Android platforms sync their localizations with a shared JSON file.

## Architecture

```
shared/localizations.json    ← Single source of truth
         ↓                ↓
    iOS Tests        Android Tests
         ↓                ↓
Localizable.strings   strings.xml
```

### Why This Approach?

**✅ Benefits:**
- **Single source of truth**: One JSON file for all strings
- **Guaranteed consistency**: Tests fail if platforms drift apart
- **Easy updates**: Change JSON once, both platforms must sync
- **Clear platform differences**: Documented in JSON with reasons
- **No hardcoded values**: Tests read expected values from JSON

**❌ Previous Approach (Abandoned):**
- Hardcoded expected values in tests
- Tests broke on legitimate string updates
- No actual cross-platform comparison
- Manual sync required

## File Structure

### Shared Localization File

**Location:** `shared/localizations.json`

**Structure:**
```json
{
  "version": "1.0.0",
  "strings": {
    "app": {
      "title": {
        "value": "Just Spent",
        "comment": "App name",
        "platforms": {
          "ios": "app.title",
          "android": "app_name"
        }
      }
    }
  },
  "platformDifferences": {
    "documented": [
      {
        "key": "emptyState.tapVoiceButton",
        "reason": "Different UI terminology",
        "ios": "Tap the voice button...",
        "android": "Tap the microphone button..."
      }
    ]
  }
}
```

### Platform-Specific Keys

Strings can have **shared values** (same on both platforms) or **platform-specific values**:

**Shared Value:**
```json
"title": {
  "value": "Just Spent",  // ← Same on both platforms
  "platforms": {
    "ios": "app.title",
    "android": "app_name"
  }
}
```

**Platform-Specific Value:**
```json
"tapVoiceButton": {
  "value": {
    "ios": "Tap the voice button...",      // ← Different
    "android": "Tap the microphone..."    // ← Different
  },
  "platformSpecific": true,
  "platforms": { ... }
}
```

## Test Files

### iOS Test

**Location:** `ios/JustSpent/JustSpentTests/LocalizationConsistencyTests.swift`

**What it validates:**
1. ✅ All shared strings exist in `Localizable.strings`
2. ✅ String values match expected values from JSON
3. ✅ Platform-specific iOS strings are correct
4. ✅ No empty strings
5. ✅ Category count matches expectations
6. ✅ Platform differences are documented

### Android Test

**Location:** `android/app/src/test/java/com/justspent/app/LocalizationConsistencyTest.kt`

**What it validates:**
1. ✅ All shared strings exist in `strings.xml`
2. ✅ String values match expected values from JSON
3. ✅ Platform-specific Android strings are correct
4. ✅ No empty strings
5. ✅ Category count matches expectations
6. ✅ Platform differences are documented

## Running the Tests

### iOS

#### Command Line
```bash
cd ios/JustSpent
xcodebuild test \
  -project JustSpent.xcodeproj \
  -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:JustSpentTests/LocalizationConsistencyTests
```

#### Xcode
1. Open `JustSpent.xcodeproj`
2. Press `⌘ + 6` (Test Navigator)
3. Click ▶️ next to `LocalizationConsistencyTests`

### Android

#### Command Line
```bash
cd android
./gradlew testDebugUnitTest --tests "*LocalizationConsistencyTest*"
```

#### Android Studio
1. Open Android project
2. Navigate to `LocalizationConsistencyTest.kt`
3. Right-click → Run 'LocalizationConsistencyTest'

## Workflow

### Adding a New String

**Step 1: Add to shared JSON**
```json
// shared/localizations.json
"newFeature": {
  "title": {
    "value": "My New Feature",
    "comment": "New feature title",
    "platforms": {
      "ios": "newFeature.title",
      "android": "new_feature_title"
    }
  }
}
```

**Step 2: Update test mappings**

**iOS:**
```swift
// LocalizationConsistencyTests.swift
private let keyMapping: [String: String] = [
    // ... existing
    "newFeature.title": "newFeature.title"
]

private let expectedValues: [String: String] = [
    // ... existing
    "newFeature.title": "My New Feature"
]
```

**Android:**
```kotlin
// LocalizationConsistencyTest.kt
private val keyMapping = mapOf(
    // ... existing
    "newFeature.title" to R.string.new_feature_title
)

private val expectedValues = mapOf(
    // ... existing
    "newFeature.title" to "My New Feature"
)
```

**Step 3: Add to platform files**

**iOS:**
```swift
// Localizable.strings
"newFeature.title" = "My New Feature";

// LocalizedStrings.swift
static let newFeatureTitle = NSLocalizedString("newFeature.title", comment: "")
```

**Android:**
```xml
<!-- strings.xml -->
<string name="new_feature_title">My New Feature</string>
```

**Step 4: Run tests**
```bash
# iOS
cd ios/JustSpent
xcodebuild test -only-testing:JustSpentTests/LocalizationConsistencyTests

# Android
cd android
./gradlew testDebugUnitTest --tests "*LocalizationConsistencyTest*"
```

### Updating an Existing String

**Step 1: Update shared JSON**
```json
"app": {
  "title": {
    "value": "Just Spent 2.0",  // ← Changed
    "comment": "App name",
    "platforms": { ... }
  }
}
```

**Step 2: Update test expected values**

**iOS:**
```swift
private let expectedValues: [String: String] = [
    "app.title": "Just Spent 2.0"  // ← Changed
]
```

**Android:**
```kotlin
private val expectedValues = mapOf(
    "app.title" to "Just Spent 2.0"  // ← Changed
)
```

**Step 3: Update platform files**

**iOS:**
```swift
"app.title" = "Just Spent 2.0";  // ← Changed
```

**Android:**
```xml
<string name="app_name">Just Spent 2.0</string>  // ← Changed
```

**Step 4: Run tests to verify**
Both tests should pass, confirming platforms are in sync.

### Adding Platform-Specific Strings

When iOS and Android need different text:

**Step 1: Add to shared JSON with platformSpecific flag**
```json
"settingsPath": {
  "value": {
    "ios": "Settings > Privacy & Security",
    "android": "Settings > Privacy"
  },
  "comment": "Different OS settings paths",
  "platformSpecific": true,
  "platforms": {
    "ios": "settings.path",
    "android": "settings_path"
  }
}
```

**Step 2: Add to platformSpecific in tests**

**iOS:**
```swift
private let platformSpecific: [String: String] = [
    "settingsPath": "Settings > Privacy & Security"
]
```

**Android:**
```kotlin
private val platformSpecific = mapOf(
    "settingsPath" to "Settings > Privacy"
)
```

**Step 3: Document in platformDifferences**
```json
"platformDifferences": {
  "documented": [
    {
      "key": "settingsPath",
      "reason": "Different OS settings structure",
      "ios": "Settings > Privacy & Security",
      "android": "Settings > Privacy"
    }
  ]
}
```

## Understanding Test Results

### ✅ All Tests Pass

Both platforms are in sync with `shared/localizations.json`:
```
✓ testAllSharedStringsExistInIOS
✓ testSharedStringsMatchExpectedValues
✓ testPlatformSpecificStringsAreCorrect
✓ testNoEmptyStrings
✓ testCategoryCountMatches
```

### ❌ Test Failures

#### Missing String
```
❌ testAllSharedStringsExistInAndroid
Missing Android string resources:
app.title → Android resource: 2131689472
```

**Fix:** Add the string to `strings.xml`:
```xml
<string name="app_name">Just Spent</string>
```

#### Value Mismatch
```
❌ testSharedStringsMatchExpectedValues
Localization mismatches:

JSON key: categories.foodDining
  Expected: 'Food & Dining'
  Actual: 'Food and Dining'
```

**Fix:** Update `strings.xml` to match JSON:
```xml
<string name="category_food_dining">Food &amp; Dining</string>
```

#### Platform-Specific Mismatch
```
❌ testPlatformSpecificStringsAreCorrect
Platform-specific string mismatches:

JSON key: emptyState.tapVoiceButton (platform-specific)
  Expected: 'Tap the microphone button to add an expense'
  Actual: 'Tap the mic button'
```

**Fix:** Update Android platform-specific string to match JSON.

## Platform Differences

### Documented Intentional Differences

| Key | iOS | Android | Reason |
|-----|-----|---------|--------|
| `emptyState.tapVoiceButton` | "Tap the voice button..." | "Tap the microphone button..." | Different UI terminology |
| `voiceAssistant.name` | "Siri" | "Assistant" | Platform branding |

These differences are **intentional** and **documented** in both:
- `shared/localizations.json` → `platformDifferences.documented[]`
- Test output (printed during test runs)

## CI/CD Integration

### Local CI

```bash
./local-ci.sh --all --quick
```

Localization tests run as part of unit tests.

### GitHub Actions

Tests run automatically on:
- Push to `main`
- Pull requests to `main`

## Best Practices

### ✅ Do

1. **Always update JSON first** before platform files
2. **Run both platform tests** after changes
3. **Document platform differences** with clear reasons
4. **Use semantic keys** in JSON (e.g., `app.title` not `str_001`)
5. **Add comments** in JSON for context

### ❌ Don't

1. **Don't** update platform files without updating JSON
2. **Don't** create platform differences without documenting why
3. **Don't** use hardcoded values outside of JSON
4. **Don't** skip tests after localization changes
5. **Don't** ignore test failures

## Troubleshooting

### Q: Test fails after legitimate string change

**A:** You need to update the expected value in **three places**:
1. `shared/localizations.json` (source of truth)
2. Test's `expectedValues` (iOS and Android)
3. Platform files (`Localizable.strings` and `strings.xml`)

### Q: How do I add a string that's iOS-only or Android-only?

**A:** Don't add it to `shared/localizations.json`. These tests only validate **shared** strings. Platform-specific implementation strings can exist outside this system.

### Q: Tests pass but strings are different between platforms

**A:** Check if the string is in the `platformSpecific` dictionaries. If not, it should be added to regular `expectedValues` with the same value for both platforms.

### Q: Can I remove the JSON file and just use tests?

**A:** No. The JSON is the **single source of truth**. Without it, tests would need hardcoded values, making them brittle and defeating the purpose.

## Future Enhancements

Potential improvements:

1. **Automated sync script**: Read JSON and auto-generate platform files
2. **JSON validation**: JSON schema validation pre-commit
3. **Coverage report**: Show which JSON strings are covered by tests
4. **Multi-language support**: Extend JSON to support multiple languages

## Related Documentation

- `CLAUDE.md` - Project coding standards (includes TDD)
- `TESTING-GUIDE.md` - General testing guide
- `data-models-spec.md` - Data model specifications

---

**Last Updated:** January 2025
**Maintained By:** Development Team
**Approach:** Single Source of Truth via JSON
