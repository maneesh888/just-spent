# Migration Guide - Refactoring to Clean Architecture

## Overview

This guide will help you migrate the existing Just Spent codebase to the new Clean Architecture structure with centralized strings and constants.

## Table of Contents

1. [Before You Start](#before-you-start)
2. [iOS Migration Steps](#ios-migration-steps)
3. [Android Migration Steps](#android-migration-steps)
4. [Common Refactoring Patterns](#common-refactoring-patterns)
5. [Testing After Migration](#testing-after-migration)
6. [Rollback Strategy](#rollback-strategy)

---

## Before You Start

### Prerequisites

- ✅ Backup your code or ensure you're in a Git branch
- ✅ All tests are passing in the current state
- ✅ Development environment is set up and working
- ✅ You've read the ARCHITECTURE_OVERVIEW.md

### Created Files & Folders

The following new structure has been created:

#### iOS
- ✅ `ios/JustSpent/JustSpent/Resources/Localizable.strings`
- ✅ `ios/JustSpent/JustSpent/Common/LocalizedStrings.swift`
- ✅ `ios/JustSpent/JustSpent/Common/Constants/AppConstants.swift`
- ✅ `ios/JustSpent/JustSpent/Common/Utilities/VoiceCommandParser.swift`
- ✅ Folder structure: `Presentation/`, `Domain/`, `Data/`, `Common/`, `Siri/`

#### Android
- ✅ `android/app/src/main/res/values/strings.xml` (updated)
- 📝 TODO: Create `AppConstants.kt`
- 📝 TODO: Create `VoiceCommandParser.kt`

---

## iOS Migration Steps

### Step 1: Update Xcode Project File Groups

**Action**: Reorganize file groups in Xcode to match the new folder structure.

1. Open `JustSpent.xcodeproj` in Xcode
2. Create groups matching the new folder structure:
   - Presentation (Views, ViewModels)
   - Domain (Models, UseCases, Interfaces)
   - Data (Repositories, CoreData, Persistence)
   - Common (Extensions, Utilities, Constants)
   - Resources
   - Siri

3. Move existing files to appropriate groups:
   - `ContentView.swift` → `Presentation/Views/`
   - `ExpenseListViewModel.swift` → `Presentation/ViewModels/`
   - `ExpenseRepository.swift` → `Data/Repositories/`
   - `PersistenceController.swift` → `Data/Persistence/`
   - `ExpenseError.swift` → `Domain/Models/`

### Step 2: Refactor ContentView.swift to Use LocalizedStrings

**Current Code Example** (ContentView.swift:47-52):
```swift
Text("Just Spent")
    .font(.largeTitle)
    .fontWeight(.bold)
Text("Voice-enabled expense tracker")
    .font(.caption)
    .foregroundColor(.secondary)
```

**Refactored Code**:
```swift
Text(LocalizedStrings.appTitle)
    .font(.largeTitle)
    .fontWeight(.bold)
Text(LocalizedStrings.appSubtitle)
    .font(.caption)
    .foregroundColor(.secondary)
```

**Find and Replace Patterns**:

| Old Code | New Code |
|----------|----------|
| `"Just Spent"` | `LocalizedStrings.appTitle` |
| `"Voice-enabled expense tracker"` | `LocalizedStrings.appSubtitle` |
| `"Total"` | `LocalizedStrings.totalLabel` |
| `"No expenses yet"` | `LocalizedStrings.emptyStateNoExpenses` |
| `"Listening..."` | `LocalizedStrings.voiceListening` |
| `"Processing..."` | `LocalizedStrings.voiceProcessing` |
| `"Grant Permissions"` | `LocalizedStrings.buttonGrantPermissions` |
| `"OK"` | `LocalizedStrings.buttonOK` |
| `"Cancel"` | `LocalizedStrings.buttonCancel` |
| `"Retry"` | `LocalizedStrings.buttonRetry` |

**Complete Refactoring**:

```swift
// Add import at top of file
import Foundation

// Example: Line 79-88 refactoring
if speechRecognitionAvailable && speechPermissionGranted && microphonePermissionGranted {
    Image(systemName: "mic.circle")
        .font(.system(size: 60))
        .foregroundColor(.blue)

    VStack(spacing: 12) {
        Text(LocalizedStrings.emptyStateNoExpenses)
            .font(.title2)
            .foregroundColor(.secondary)

        Text(LocalizedStrings.emptyStateTapVoiceButton)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}
```

### Step 3: Refactor Voice Command Processing to Use VoiceCommandParser

**Current Code** (ContentView.swift:376-482):
The `extractExpenseData` function is currently defined inline in ContentView.

**Refactored Code**:

```swift
private func processVoiceTranscription(_ transcription: String) {
    print(LocalizedStrings.debugProcessingTranscription(transcription))

    // Validate input
    guard !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        siriMessage = LocalizedStrings.voiceRecognitionSpeakClearly
        isErrorMessage = true
        showingSiriSuccess = true
        return
    }

    // Use VoiceCommandParser utility
    let parsedData = VoiceCommandParser.shared.parseExpenseCommand(transcription)

    // Debug output
    #if DEBUG
    print(LocalizedStrings.debugExtracted(
        amount: String(parsedData.amount ?? 0),
        currency: parsedData.currency ?? "none",
        category: parsedData.category ?? "none"
    ))
    #endif

    if let amount = parsedData.amount,
       let category = parsedData.category {

        Task {
            do {
                let repository = ExpenseRepository()
                let expenseData = ExpenseData(
                    amount: NSDecimalNumber(value: amount),
                    currency: parsedData.currency ?? AppConstants.Currency.defaultCurrency,
                    category: category,
                    merchant: parsedData.merchant,
                    notes: LocalizedStrings.expenseAddedViaVoice,
                    transactionDate: Date(),
                    source: AppConstants.ExpenseSource.voiceRecognition,
                    voiceTranscript: transcription
                )

                _ = try await repository.addExpense(expenseData)

                await MainActor.run {
                    siriMessage = LocalizedStrings.expenseAddedSuccess(
                        currency: parsedData.currency ?? "",
                        amount: String(amount),
                        category: category,
                        transcript: transcription
                    )
                    showingSiriSuccess = true
                    Task {
                        await viewModel.loadExpenses()
                    }
                }

            } catch {
                await MainActor.run {
                    siriMessage = LocalizedStrings.expenseFailedToSave(error.localizedDescription)
                    isErrorMessage = true
                    showingSiriSuccess = true
                }
            }
        }
    } else {
        siriMessage = LocalizedStrings.expenseCouldNotUnderstand(transcription)
        isErrorMessage = true
        showingSiriSuccess = true
    }
}
```

**Then DELETE** the old `extractExpenseData` function (lines 376-537) as it's now handled by `VoiceCommandParser`.

### Step 4: Refactor AppConstants Usage

Replace hardcoded constants with `AppConstants`:

```swift
// Voice Recording Configuration
// Old:
@State private var silenceThreshold: TimeInterval = 2.0
@State private var minimumSpeechDuration: TimeInterval = 1.0

// New:
@State private var silenceThreshold = AppConstants.VoiceRecording.silenceThreshold
@State private var minimumSpeechDuration = AppConstants.VoiceRecording.minimumSpeechDuration

// User Activity Types
// Old:
.onContinueUserActivity("com.justspent.logExpense") { userActivity in

// New:
.onContinueUserActivity(AppConstants.UserActivityType.logExpense) { userActivity in

// Category References
// Old:
let category = "Food & Dining"

// New:
let category = AppConstants.Category.foodDining

// Source Types
// Old:
source: "voice_siri"

// New:
source: AppConstants.ExpenseSource.voiceSiri
```

### Step 5: Update JustSpentApp.swift

Similar refactoring for `JustSpentApp.swift`:

```swift
// Replace extractExpenseData function call
let extractedData = VoiceCommandParser.shared.parseExpenseCommand(command)

// Use AppConstants for user activities
.onContinueUserActivity(AppConstants.UserActivityType.logExpense) { userActivity in
    handleSiriExpense(userActivity)
}
.onContinueUserActivity(AppConstants.UserActivityType.viewExpenses) { userActivity in
    print("📊 Siri requested to view expenses")
}
.onContinueUserActivity(AppConstants.UserActivityType.processVoiceCommand) { userActivity in
    handleVoiceCommandProcessing(userActivity)
}

// Use LocalizedStrings for debug messages
#if DEBUG
print(LocalizedStrings.debugSavedExpense(amount: String(amount), category: category))
#endif
```

### Step 6: Update Info.plist References

Ensure `Localizable.strings` is included in the app target:

1. Select `Localizable.strings` in Xcode
2. In File Inspector, ensure "Target Membership" includes "JustSpent"
3. Clean build folder (Product > Clean Build Folder)
4. Build and test

---

## Android Migration Steps

### Step 1: Create AppConstants.kt

Create `android/app/src/main/java/com/justspent/app/constants/AppConstants.kt`:

```kotlin
package com.justspent.expense.constants

object AppConstants {

    object UserActivityType {
        const val LOG_EXPENSE = "com.justspent.logExpense"
        const val VIEW_EXPENSES = "com.justspent.viewExpenses"
    }

    object VoiceRecording {
        const val SILENCE_THRESHOLD_MS = 2000L
        const val MINIMUM_SPEECH_DURATION_MS = 1000L
        const val SILENCE_CHECK_INTERVAL_MS = 500L
    }

    object Category {
        const val FOOD_DINING = "Food & Dining"
        const val GROCERY = "Grocery"
        const val TRANSPORTATION = "Transportation"
        const val SHOPPING = "Shopping"
        const val ENTERTAINMENT = "Entertainment"
        const val BILLS_UTILITIES = "Bills & Utilities"
        const val HEALTHCARE = "Healthcare"
        const val EDUCATION = "Education"
        const val OTHER = "Other"

        val ALL_CATEGORIES = listOf(
            FOOD_DINING,
            GROCERY,
            TRANSPORTATION,
            SHOPPING,
            ENTERTAINMENT,
            BILLS_UTILITIES,
            HEALTHCARE,
            EDUCATION,
            OTHER
        )
    }

    object CategoryKeywords {
        val MAPPINGS = listOf(
            // Food & Dining
            CategoryMapping(
                keywords = listOf("food", "tea", "coffee", "lunch", "dinner", "breakfast",
                    "restaurant", "meal", "drink", "cafe", "dining", "eat", "ate", "snack"),
                category = Category.FOOD_DINING
            ),
            // Add other categories...
        )
    }

    data class CategoryMapping(
        val keywords: List<String>,
        val category: String
    )

    object Currency {
        const val DEFAULT = "USD"
        val SUPPORTED = listOf("USD", "AED", "EUR", "GBP", "INR")
    }

    object ExpenseSource {
        const val MANUAL = "manual"
        const val VOICE_ASSISTANT = "voice_assistant"
        const val VOICE_RECOGNITION = "voice_recognition"
        const val IMPORT = "import"
    }
}
```

### Step 2: Create VoiceCommandParser.kt

Create `android/app/src/main/java/com/justspent/app/util/VoiceCommandParser.kt`:

```kotlin
package com.justspent.expense.util

import com.justspent.expense.constants.AppConstants

data class ParsedExpenseData(
    val amount: Double?,
    val currency: String?,
    val category: String?,
    val merchant: String?
)

object VoiceCommandParser {

    fun parseExpenseCommand(command: String): ParsedExpenseData {
        val lowercased = command.lowercase()

        // Extract amount and currency
        var amount: Double? = null
        var currency = AppConstants.Currency.DEFAULT

        // Try numeric patterns
        val patterns = listOf(
            Regex("""(\d+(?:\.\d{1,2})?)\s*(?:dirhams?|aed)""") to "AED",
            Regex("""(\d+(?:\.\d{1,2})?)\s*(?:dollars?|usd|\$)""") to "USD",
            Regex("""(\d+(?:\.\d{1,2})?)\s*(?:euros?|eur|€)""") to "EUR",
            Regex("""(\d+(?:\.\d{1,2})?)\s*(?:pounds?|gbp|£)""") to "GBP",
            Regex("""(\d+(?:\.\d{1,2})?)""") to "USD"
        )

        for ((pattern, curr) in patterns) {
            val match = pattern.find(lowercased)
            if (match != null) {
                amount = match.groupValues[1].toDoubleOrNull()
                if (amount != null) {
                    currency = curr
                    break
                }
            }
        }

        // Extract category
        val category = extractCategory(lowercased)

        // Extract merchant
        val merchant = extractMerchant(lowercased)

        return ParsedExpenseData(amount, currency, category, merchant)
    }

    private fun extractCategory(command: String): String {
        for (mapping in AppConstants.CategoryKeywords.MAPPINGS) {
            if (mapping.keywords.any { command.contains(it) }) {
                return mapping.category
            }
        }
        return AppConstants.Category.OTHER
    }

    private fun extractMerchant(command: String): String? {
        val pattern = Regex("""(?:at|from)\s+([a-zA-Z\s]+?)(?:\s|$)""")
        return pattern.find(command)?.groupValues?.get(1)?.trim()
    }
}
```

### Step 3: Update Existing Android Code

Replace hardcoded strings with string resources:

```kotlin
// Old:
Text("Just Spent")

// New:
Text(stringResource(R.string.app_name))

// Old:
category = "Food & Dining"

// New:
category = AppConstants.Category.FOOD_DINING
```

---

## Common Refactoring Patterns

### Pattern 1: Replace Hardcoded Strings

**Search for**: `"Text in quotes"`
**Replace with**: Appropriate localized string

### Pattern 2: Replace Magic Numbers/Strings

**Search for**: Inline constants
**Replace with**: `AppConstants.NamedConstant`

### Pattern 3: Extract Voice Parsing

**Search for**: Inline regex and parsing logic
**Replace with**: `VoiceCommandParser.shared.parseExpenseCommand()` (iOS)
                   `VoiceCommandParser.parseExpenseCommand()` (Android)

### Pattern 4: Organize Imports

After refactoring, organize imports:

**iOS**:
```swift
import SwiftUI
import CoreData
import Speech
import AVFoundation
import NaturalLanguage
import Intents
import IntentsUI
```

**Android**:
```kotlin
import android.content.Context
import androidx.compose.runtime.*
import com.justspent.expense.constants.AppConstants
import com.justspent.expense.util.VoiceCommandParser
```

---

## Testing After Migration

### Unit Test Checklist

- [ ] Test `VoiceCommandParser` with various voice command formats
- [ ] Test LocalizedStrings returns non-empty strings
- [ ] Test AppConstants have correct values
- [ ] Test ViewModels with new refactored code
- [ ] Test Repository operations still work

### Integration Test Checklist

- [ ] Test voice command end-to-end flow
- [ ] Test expense creation with new parser
- [ ] Test localization switching (if multi-language supported)
- [ ] Test Siri/Assistant integration still works

### UI Test Checklist

- [ ] All text displays correctly
- [ ] Voice recording still functions
- [ ] Permission dialogs show correct text
- [ ] Error messages are localized

### Manual Testing

1. **Test voice command**: "I just spent 20 dollars for tea"
   - Should extract: amount=20, currency=USD, category="Food & Dining"

2. **Test written numbers**: "I spent twenty dollars on lunch"
   - Should extract: amount=20, currency=USD, category="Food & Dining"

3. **Test different categories**:
   - "50 dirhams for gas" → Transportation
   - "100 dollars shopping" → Shopping
   - "15 dollars at Starbucks" → Food & Dining

4. **Test permissions**:
   - Deny permissions and verify error messages show correctly
   - Grant permissions and verify success messages

---

## Rollback Strategy

If you encounter issues:

### Git Rollback
```bash
# If you committed the changes
git revert HEAD

# If changes are unstaged
git checkout -- .

# If changes are staged
git reset HEAD
git checkout -- .
```

### Manual Rollback

1. Keep backup of original files
2. Restore from backup if needed
3. Remove new files (VoiceCommandParser, LocalizedStrings, AppConstants)
4. Update Xcode project to remove file references

---

## Success Criteria

✅ All hardcoded strings replaced with localized strings
✅ All magic values replaced with constants
✅ Voice parsing logic extracted to VoiceCommandParser
✅ Files organized in proper architecture folders
✅ All tests passing
✅ No build errors
✅ App functions identically to before refactoring
✅ Code is more maintainable and testable

---

## Next Steps After Migration

1. **Add More Localization**: Add support for additional languages
2. **Write More Tests**: Increase test coverage with new architecture
3. **Extract More Use Cases**: Create dedicated use case classes
4. **Implement Protocols**: Add repository protocols for better testability
5. **Document APIs**: Add comprehensive code documentation

---

## Getting Help

If you encounter issues during migration:

1. Check the `ARCHITECTURE_OVERVIEW.md` for architectural guidance
2. Review the `ios/ARCHITECTURE.md` for iOS-specific details
3. Look at the created helper files for usage examples
4. Test incrementally - don't refactor everything at once

---

*Last Updated: October 2024*
*Migration Version: 1.0*
