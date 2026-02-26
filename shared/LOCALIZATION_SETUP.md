# Localization Setup Guide

## Overview

This project uses a **single source of truth** for localization strings: `shared/localizations.json`

Both iOS and Android reference this file, ensuring cross-platform consistency.

## Architecture

```
shared/localizations.json (master file)
    ↓
    ├─→ iOS: Loads from shared folder or bundle
    └─→ Android: Gradle copies to assets during build
```

## File Structure

```
just-spent/
├── shared/
│   └── localizations.json              ← SINGLE SOURCE OF TRUTH
├── ios/JustSpent/JustSpent/
│   └── Common/
│       └── LocalizationManager.swift   ← Loads from shared or bundle
├── android/app/
│   ├── src/main/
│   │   ├── assets/
│   │   │   ├── .gitignore              ← Ignores copied file
│   │   │   └── localizations.json      ← Auto-copied during build (ignored by git)
│   │   └── java/com/justspent/app/utils/
│   │       └── LocalizationManager.kt  ← Loads from shared or assets
│   └── build.gradle.kts                ← Contains copy task
```

## Setup Instructions

### iOS Setup

#### Option 1: Reference Mode (Development & Testing)
No Xcode setup needed! The `LocalizationManager.swift` automatically finds the shared file during development and testing.

**How it works:**
1. Tests run from project root → finds `shared/localizations.json` directly
2. Simulator builds → navigates up from bundle path to find shared folder
3. Both modes load the same file → guaranteed consistency

#### Option 2: Bundle Mode (Production Builds)
For production builds where the app runs standalone without the project structure:

1. Open `JustSpent.xcodeproj` in Xcode
2. Right-click on `JustSpent/Resources` folder in Project Navigator
3. Select **"Add Files to JustSpent..."**
4. Navigate to `shared/localizations.json`
5. **IMPORTANT:** Uncheck **"Copy items if needed"** (we want a reference, not a copy)
6. Check **"Create folder references"** (not "Create groups")
7. Ensure target **"JustSpent"** is selected
8. Click **"Add"**

The file will appear in Xcode with a folder icon (📁) instead of a file icon, indicating it's a reference.

**Verification:**
- File shows as `localizations.json` under Resources
- File icon is a folder (📁) not a document
- Clicking it opens the file from `shared/` folder
- Changes to `shared/localizations.json` immediately reflect in Xcode

### Android Setup

**Automatic!** No manual setup required.

The Gradle build script (`android/app/build.gradle.kts`) contains a `copySharedLocalizations` task that:
1. Runs before every build
2. Copies `shared/localizations.json` to `android/app/src/main/assets/`
3. The copied file is ignored by git (see `android/app/src/main/assets/.gitignore`)

**How it works:**
```kotlin
// Gradle task in build.gradle.kts
tasks.register<Copy>("copySharedLocalizations") {
    from("${project.rootDir}/../shared/localizations.json")
    into("${project.projectDir}/src/main/assets")
}

// Auto-runs before preBuild
tasks.whenTaskAdded {
    if (name == "preBuild") {
        dependsOn("copySharedLocalizations")
    }
}
```

**LocalizationManager.kt strategy:**
1. First tries to load from `shared/` folder (for unit tests)
2. Falls back to assets (for instrumented tests and production APK)

## How to Update Localizations

### 1. Edit the Master File

Edit `shared/localizations.json`:

```json
{
  "version": "1.0.0",
  "app": {
    "title": "Just Spent",
    "subtitle": "Voice-enabled expense tracker"
  },
  "categories": {
    "foodDining": "Food & Dining",
    "newCategory": "New Category"  ← Add new strings here
  }
}
```

### 2. Platform-Specific Strings

Use nested objects with `"ios"` and `"android"` keys:

```json
{
  "emptyState": {
    "tapVoiceButton": {
      "ios": "Tap the voice button below to get started",
      "android": "Tap the microphone button to add an expense"
    }
  },
  "voiceAssistant": {
    "name": {
      "ios": "Siri",
      "android": "Assistant"
    }
  }
}
```

The `LocalizationManager` on each platform automatically selects the correct value.

### 3. Access Strings in Code

#### iOS (Swift)

```swift
// Using convenience properties
let title = LocalizationManager.shared.appTitle
let subtitle = LocalizationManager.shared.appSubtitle

// Using dot notation
let total = LocalizationManager.shared.get("app.totalLabel")
let category = LocalizationManager.shared.get("categories.foodDining")
```

#### Android (Kotlin)

```kotlin
// Using convenience properties
val title = LocalizationManager.getInstance(context).appTitle
val subtitle = LocalizationManager.getInstance(context).appSubtitle

// Using dot notation
val total = LocalizationManager.getInstance(context).get("app.totalLabel")
val category = LocalizationManager.getInstance(context).get("categories.foodDining")
```

### 4. Build & Test

**iOS:**
```bash
cd ios/JustSpent
xcodebuild test -scheme JustSpent -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Android:**
```bash
cd android
./gradlew testDebugUnitTest --tests "LocalizationConsistencyTest"
```

Both platforms will load the updated strings automatically!

## Testing

### Tests Verify:

1. **JSON Loading Works** - Both platforms can load the file
2. **Dot-Notation Access** - Path-based string retrieval works
3. **Platform-Specific Selection** - iOS gets "ios" values, Android gets "android" values
4. **Cross-Platform Consistency** - Shared strings are identical

### Test Files:

- `ios/JustSpent/JustSpentTests/LocalizationConsistencyTests.swift`
- `android/app/src/test/java/com/justspent/app/LocalizationConsistencyTest.kt`

## Troubleshooting

### iOS: "Failed to load localizations.json"

**Check:**
1. Verify `shared/localizations.json` exists in project root
2. Run test from project root directory
3. Check Xcode Console for path search output

**Debug:**
```swift
// LocalizationManager prints search paths:
📍 Found localizations.json in shared folder (from current dir)
// or
📍 Found localizations.json in shared folder (from bundle path)
// or
📍 Found localizations.json in app bundle
// or
❌ Failed to load localizations.json from any location
```

### Android: "Failed to load localizations.json"

**Check:**
1. Verify `shared/localizations.json` exists
2. For unit tests: Run from project root
3. For APK builds: Verify Gradle task ran

**Debug:**
```bash
# Run build with verbose output
cd android
./gradlew assembleDebug --info | grep localization

# Should see:
# 📋 Copying shared/localizations.json to Android assets...
# ✅ Copied shared localization file to assets
```

### Git Shows assets/localizations.json as Changed

**Fix:**
```bash
# This file should be ignored by git
git check-ignore android/app/src/main/assets/localizations.json
# Should output: android/app/src/main/assets/localizations.json

# If not ignored, verify .gitignore exists:
cat android/app/src/main/assets/.gitignore
# Should contain: localizations.json

# Force git to respect .gitignore:
git rm --cached android/app/src/main/assets/localizations.json
```

## Benefits

✅ **Single Source of Truth** - Update once, both platforms reflect changes
✅ **No Duplication** - Strings defined in one place only
✅ **Platform-Specific Support** - Handle "Siri" vs "Assistant" gracefully
✅ **Git-Friendly** - Master file tracked, copies ignored
✅ **Test-Driven** - Tests verify consistency automatically
✅ **Easy Updates** - Edit JSON, rebuild, done!

## Future: Multi-Language Support

When adding new languages, structure the JSON like this:

```json
{
  "version": "2.0.0",
  "en": {
    "app": {
      "title": "Just Spent",
      "subtitle": "Voice-enabled expense tracker"
    }
  },
  "ar": {
    "app": {
      "title": "تم الإنفاق",
      "subtitle": "متتبع النفقات الصوتي"
    }
  }
}
```

Update `LocalizationManager` to load based on device locale.
