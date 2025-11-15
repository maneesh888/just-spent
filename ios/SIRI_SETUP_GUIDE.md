# Siri Integration Setup Guide for Just Spent

## 🎯 Problem Identified

Siri is not recognizing the Just Spent app because the **Intents Extension target is missing** from the Xcode project. While the intent handler code exists, it's not properly registered as an extension.

## ✅ What We Have

- ✅ `IntentHandler.swift` - Complete implementation
- ✅ `JustSpent.intentdefinition` - Properly configured intents
- ✅ Info.plist with Siri usage descriptions
- ✅ SharedDataManager for data sharing
- ✅ Entitlements files (newly created)

## ❌ What's Missing

- ❌ **Intents Extension target** (critical!)
- ❌ Xcode project configuration for the extension
- ❌ Siri capability enabled in project
- ❌ App Groups capability enabled
- ❌ Shortcuts donation in main app

## 🔧 Step-by-Step Fix (In Xcode)

### Step 1: Add Intents Extension Target

1. Open `JustSpent.xcodeproj` in Xcode
2. Click on the project name in the navigator
3. Click the **"+"** button at the bottom of the targets list
4. Select **iOS → Application Extension → Intents Extension**
5. Click **Next**

**Configuration:**
- **Product Name**: `JustSpentIntents`
- **Team**: Your Apple Developer Team
- **Language**: Swift
- **Starting Point**: None (we'll use existing code)
- **Include UI Extension**: ✅ Check this (optional but recommended)

6. Click **Finish**
7. When prompted about activating the scheme, click **Activate**

### Step 2: Configure the Intents Extension

1. **Delete** the generated `IntentHandler.swift` file (we already have one)
2. **Add existing files** to the target:
   - Right-click `SiriKit/IntentHandler.swift`
   - Select **Target Membership**
   - Check ✅ **JustSpentIntents**

3. **Add the intent definition file**:
   - Select `JustSpent.intentdefinition`
   - In File Inspector (right panel), ensure both targets are checked:
     - ✅ JustSpent
     - ✅ JustSpentIntents

### Step 3: Configure App Groups

1. Select the **JustSpent** target
2. Go to **Signing & Capabilities** tab
3. Click **"+ Capability"**
4. Add **App Groups**
5. Click **"+"** under App Groups
6. Enter: `group.com.justspent.shared`
7. Click **OK**

8. Repeat for **JustSpentIntents** target:
   - Select JustSpentIntents target
   - Add App Groups capability
   - Use the same group: `group.com.justspent.shared`

### Step 4: Enable Siri Capability

1. Select the **JustSpent** target
2. Go to **Signing & Capabilities**
3. Click **"+ Capability"**
4. Add **Siri**

### Step 5: Add Entitlements Files

1. Select **JustSpent** target
2. Go to **Build Settings**
3. Search for "Code Signing Entitlements"
4. Set to: `JustSpent/JustSpent.entitlements`

5. Select **JustSpentIntents** target
6. Go to **Build Settings**
7. Search for "Code Signing Entitlements"
8. Set to: `SiriKit/JustSpentIntents.entitlements`

### Step 6: Update Info.plist for Extension

Replace the content of `SiriKit/Info.plist` with the existing one that declares supported intents:
- LogExpenseIntent
- ViewExpensesIntent

(File already exists and is correctly configured)

### Step 7: Link Core Data Model

1. Select `JustSpent.xcdatamodeld` in the project navigator
2. In **Target Membership** (File Inspector), check:
   - ✅ JustSpent
   - ✅ JustSpentIntents

### Step 8: Add Required Files to Extension Target

Ensure these files are part of the JustSpentIntents target:
- `Models/Expense+CoreDataClass.swift`
- `Models/Currency.swift`
- `Services/UserPreferences.swift`

## 🧪 Testing the Integration

### 1. Build and Run

```bash
# Clean build
Product → Clean Build Folder (⇧⌘K)

# Build main app
Product → Build (⌘B)

# Build extension
Select "JustSpentIntents" scheme → Build
```

### 2. Test on Device (Required for Siri)

⚠️ **Important**: Siri testing requires a **physical device**. Simulator won't work!

1. Connect iPhone/iPad
2. Select your device as the target
3. Run the app
4. Grant Siri permission when prompted

### 3. Test Voice Commands

Try these phrases:
- "Hey Siri, I just spent 50 dirhams on groceries in Just Spent"
- "Hey Siri, log 20 dollars for food in Just Spent"
- "Hey Siri, I paid 100 AED for transportation"

### 4. Debug Siri Issues

If Siri doesn't recognize:

1. **Check Siri Settings**:
   - Settings → Siri & Search → Just Spent
   - Ensure "Use with Siri" is enabled

2. **Check Console Logs**:
   - Open Console app (macOS)
   - Connect device
   - Filter for "JustSpent"
   - Try a voice command
   - Look for intent handling logs

3. **Verify Extension is Running**:
   - In Xcode: Debug → Attach to Process
   - Look for "JustSpentIntents"
   - Should appear when Siri triggers intent

## 🎁 Bonus: Add Shortcuts Donation

To improve Siri recognition, donate shortcuts when users log expenses.

Add this code to `ExpenseRepository.swift` after saving an expense:

```swift
import Intents

func donateShortcut(for expense: Expense) {
    let intent = LogExpenseIntent()
    intent.amount = expense.amount
    intent.currency = expense.currency
    intent.category = ExpenseCategory(rawValue: expense.category)

    let interaction = INInteraction(intent: intent, response: nil)
    interaction.donate { error in
        if let error = error {
            print("Failed to donate shortcut: \(error)")
        }
    }
}
```

## 📱 Expected Behavior After Setup

### What Should Work:

1. **Siri Recognition**:
   - "Hey Siri, I just spent [amount] on [category]" → Logs expense
   - "Hey Siri, show my expenses" → Opens app

2. **Shortcuts App**:
   - Just Spent appears in Shortcuts app
   - Can create custom shortcuts
   - Siri suggests expense logging at relevant times

3. **Lock Screen**:
   - Can log expenses without unlocking (if configured)

4. **Voice Confirmation**:
   - Siri confirms: "I've logged 50 dirhams for groceries"

## 🐛 Common Issues

### "Just Spent is not available for Siri"

**Solution**:
- Ensure Siri capability is enabled
- Check App Groups are configured
- Verify extension target is built and embedded

### "Could not communicate with app"

**Solution**:
- Verify App Groups identifier matches exactly: `group.com.justspent.shared`
- Rebuild both main app and extension
- Uninstall and reinstall app

### Intent parameters not extracted

**Solution**:
- Check `JustSpent.intentdefinition` is in both targets
- Verify synonyms are configured for categories
- Test with explicit app name: "in Just Spent"

### Extension crashes

**Solution**:
- Check memory usage (must be < 30MB)
- Verify Core Data model is accessible
- Check SharedDataManager initialization

## 📋 Verification Checklist

Before testing, verify:

- [ ] JustSpentIntents extension target exists
- [ ] App Groups configured in both targets
- [ ] Siri capability enabled in main app
- [ ] IntentHandler.swift in extension target
- [ ] JustSpent.intentdefinition in both targets
- [ ] Entitlements files configured
- [ ] Built on physical device
- [ ] Siri permission granted
- [ ] Extension scheme builds successfully

## 🎯 Success Criteria

You'll know it's working when:

1. Siri understands "I just spent..." commands
2. Expense appears in the app immediately
3. Shortcuts app shows Just Spent intents
4. Lock screen expense logging works
5. Voice confirmation is accurate

## 📞 Need Help?

If you encounter issues:

1. Check Xcode console for errors
2. Look at Console app logs (filter for "JustSpent")
3. Verify all steps completed
4. Try the sample phrases exactly as written
5. Ensure you're testing on a physical device

---

**Note**: This guide assumes you have an Apple Developer account with Siri entitlement. Free developer accounts can test locally but cannot distribute Siri-enabled apps.

## 🚀 Next Steps After Setup

1. Test all voice command patterns
2. Add shortcuts donation throughout the app
3. Customize Siri responses in `IntentHandler.swift`
4. Add Intents UI Extension for custom confirmation screens
5. Implement background modes for queue sync

---

**Last Updated**: 2025-01-15
**Status**: Ready for Implementation
