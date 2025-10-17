# iOS Test Configuration Guide

## Overview
This document describes the test configuration requirements for the Just Spent iOS app and outlines what's needed to enable the full test suite.

## Current Test Status

### ✅ Working Tests
- **ExpenseRepositoryTests.swift** - Unit tests for the expense repository layer
  - Tests CRUD operations for expenses
  - Tests category filtering
  - Tests voice transcript handling
  - All tests updated to use `AppConstants` instead of hardcoded strings

### ⚠️ Disabled Tests (Requires Intent Definition File)
- **VoiceIntegrationE2ETests.swift** - End-to-end tests for Siri voice integration
  - Currently commented out
  - Requires `JustSpent.intentdefinition` file to be created

## Test Scheme Configuration

### Issue
The Xcode scheme is not currently configured for the test action. When running:
```bash
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent
```

You get:
```
xcodebuild: error: Scheme JustSpent is not currently configured for the test action.
```

### Solution
To configure the test scheme in Xcode:

1. Open `JustSpent.xcodeproj` in Xcode
2. Click on the scheme dropdown at the top
3. Select **Edit Scheme...**
4. Select **Test** in the left sidebar
5. Click the **+** button under **Test**
6. Add `JustSpentTests` target
7. Ensure the test target is checked
8. Click **Close**

This will enable automated test execution from the command line and Xcode.

## Intent Definition File Requirements

### What's Missing
The following files require a `JustSpent.intentdefinition` file to function:

1. **ShortcutsManager.swift** (currently commented out)
   - Located: `ios/JustSpent/JustSpent/SiriKit/ShortcutsManager.swift`
   - Purpose: Manages Siri shortcuts and voice training phrases

2. **VoiceIntegrationE2ETests.swift** (currently commented out)
   - Located: `ios/JustSpentTests/Voice/VoiceIntegrationE2ETests.swift`
   - Purpose: End-to-end tests for Siri intent handling

### Intent Definition Requirements

Create `JustSpent.intentdefinition` with the following custom intents:

#### 1. LogExpenseIntent
Custom intent for logging expenses via Siri.

**Parameters:**
- `amount`: NSDecimalNumber (required)
- `currency`: String (optional, default: "USD")
- `category`: ExpenseCategory enum (optional)
- `merchant`: String (optional)
- `note`: String (optional)

**Response:**
- `code`: Success/Failure
- `amount`: NSDecimalNumber
- `category`: ExpenseCategory
- `merchant`: String
- `userActivity`: NSUserActivity

**Suggested Phrases:**
- "I just spent [amount] [currency] on [category]"
- "Log [amount] for [category] in Just Spent"
- "I paid [amount] at [merchant]"

#### 2. ViewExpensesIntent
Custom intent for viewing expenses via Siri.

**Parameters:**
- `category`: ExpenseCategory enum (optional)
- `timePeriod`: String (optional, e.g., "today", "this week", "this month")

**Response:**
- `code`: Success/Failure
- `userActivity`: NSUserActivity with expense data

**Suggested Phrases:**
- "Show my expenses for [timePeriod]"
- "What did I spend on [category]?"
- "View my [category] expenses"

#### 3. ExpenseCategory Enum
Enum type for expense categories.

**Values:**
- `foodDining` → "Food & Dining"
- `grocery` → "Grocery"
- `transportation` → "Transportation"
- `shopping` → "Shopping"
- `entertainment` → "Entertainment"
- `billsUtilities` → "Bills & Utilities"
- `healthcare` → "Healthcare"
- `education` → "Education"
- `other` → "Other"

### Required Handler Classes

Once the intent definition is created, implement these handler classes:

1. **LogExpenseIntentHandler**
   - Handles LogExpenseIntent
   - Validates parameters
   - Saves expense to shared data container
   - Returns appropriate response

2. **ViewExpensesIntentHandler**
   - Handles ViewExpensesIntent
   - Fetches expenses based on filters
   - Returns user activity with expense data

3. **SharedDataManager**
   - Manages Core Data stack with shared app group
   - Provides methods for saving and fetching expenses
   - Handles data synchronization between app and intent extension

### Implementation Steps

1. **Create Intent Definition File**
   - In Xcode, select `File > New > File`
   - Choose `SiriKit Intent Definition File`
   - Name it `JustSpent.intentdefinition`
   - Add to both `JustSpent` and `JustSpentIntentsExtension` targets

2. **Define Intents**
   - Add `LogExpenseIntent` custom intent
   - Add `ViewExpensesIntent` custom intent
   - Create `ExpenseCategory` enum
   - Configure parameters and responses
   - Add suggested invocation phrases

3. **Create Intent Extension Target** (if not exists)
   - Select `File > New > Target`
   - Choose `Intents Extension`
   - Name it `JustSpentIntentsExtension`
   - Add intent definition to this target

4. **Implement Intent Handlers**
   - Create `LogExpenseIntentHandler.swift`
   - Create `ViewExpensesIntentHandler.swift`
   - Create `SharedDataManager.swift`
   - Implement parameter resolution methods
   - Implement handle methods

5. **Configure App Groups**
   - Enable App Groups capability
   - Create shared group: `group.com.justspent.shared`
   - Use shared container for Core Data persistence

6. **Update Info.plist**
   - Add Siri usage description
   - Add supported user activity types
   - Configure intent handling

7. **Uncomment Disabled Files**
   - Uncomment `ShortcutsManager.swift`
   - Uncomment `VoiceIntegrationE2ETests.swift`
   - Update any hardcoded values to use `AppConstants`

## Migration Notes

### Updated in ExpenseRepositoryTests.swift
All test cases have been updated to use constants from `AppConstants`:

**Currency Values:**
- ❌ Old: `currency: "USD"`
- ✅ New: `currency: AppConstants.Currency.usd`
- ✅ New: `currency: AppConstants.Currency.aed`

**Source Values:**
- ❌ Old: `source: "manual"`
- ✅ New: `source: AppConstants.ExpenseSource.manual`
- ❌ Old: `source: "voice_siri"`
- ✅ New: `source: AppConstants.ExpenseSource.voiceSiri`

### Known Issues in VoiceIntegrationE2ETests.swift (when uncommented)
Line 354 uses hardcoded value:
```swift
source: .voiceSiri,  // Should be: AppConstants.ExpenseSource.voiceSiri
```

This will need to be updated when the file is uncommented.

## Running Tests

### Once Scheme is Configured

**Run all tests:**
```bash
cd /Users/maneesh/Documents/Hobby/just-spent/ios/JustSpent
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Run specific test:**
```bash
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent -only-testing:JustSpentTests/ExpenseRepositoryTests
```

**Run from Xcode:**
- Select test file in navigator
- Click the diamond icon next to test method
- Or press `Cmd+U` to run all tests

### Current Capability
Currently, only `ExpenseRepositoryTests.swift` can be run once the test scheme is configured. The voice integration tests require the intent definition file first.

## Test Coverage Goals

As per the comprehensive test plan:

- **Unit Tests:** 85% code coverage minimum
- **Integration Tests:** 70% API coverage
- **Voice Integration:** All voice patterns tested
- **Performance:** <1.5s voice processing target
- **Security:** OWASP Mobile Top 10 compliance

## References

- **Migration Guide:** `/Users/maneesh/Documents/Hobby/just-spent/MIGRATION_GUIDE.md`
- **Siri Integration Guide:** `/Users/maneesh/Documents/Hobby/just-spent/ios-siri-integration.md`
- **Comprehensive Test Plan:** `/Users/maneesh/Documents/Hobby/just-spent/comprehensive-test-plan.md`
- **AppConstants:** `ios/JustSpent/JustSpent/Common/Constants/AppConstants.swift`

## Next Steps

1. ✅ Configure Xcode test scheme
2. ⬜ Create `JustSpent.intentdefinition` file
3. ⬜ Implement intent handler classes
4. ⬜ Configure app groups for data sharing
5. ⬜ Uncomment `ShortcutsManager.swift`
6. ⬜ Uncomment and fix `VoiceIntegrationE2ETests.swift`
7. ⬜ Run full test suite
8. ⬜ Achieve 85%+ code coverage

---

*Last Updated: During iOS migration to clean architecture with centralized constants and localization*
