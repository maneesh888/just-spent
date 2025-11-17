# Siri Integration Troubleshooting Guide

## Errors You Experienced & Fixes Applied

### Error 1: "Sorry, that feature isn't available, due to your device settings or region"

**When it happens:**
- Saying: "I just spent 50 dirhams"
- Siri doesn't recognize the natural language command

**Root Cause:**
- Missing `AppIntentsMetadata` in Info.plist
- Missing App Intents entitlement key

**Fix Applied:**

1. **Added to Info.plist:**
```xml
<key>AppIntentsMetadata</key>
<dict>
    <key>AppIntentsEnabled</key>
    <true/>
    <key>NSAppIntentsSupportedEntityTypes</key>
    <array>
        <string>Expense</string>
    </array>
</dict>
```

2. **Added to JustSpent.entitlements:**
```xml
<key>com.apple.developer.appintents-extension</key>
<true/>
```

---

### Error 2: "Something went wrong" when enabling "Use with Siri"

**When it happens:**
- Saying: "Log expense in Just Spent"
- Siri asks to turn on shortcuts
- Enabling fails with "Something went wrong"

**Root Cause:**
- App Intents not properly enabled in entitlements
- Missing discoverability flags in intent definitions

**Fix Applied:**

1. **Added App Intents entitlement:**
```xml
<key>com.apple.developer.appintents-extension</key>
<true/>
```

2. **Updated LogExpenseIntent.swift:**
```swift
static var isDiscoverable: Bool = true
static var openAppWhenRun: Bool = false
```

3. **Updated ViewExpensesIntent.swift:**
```swift
static var isDiscoverable: Bool = true
static var openAppWhenRun: Bool = true
```

---

## What You Need to Do Now

### Step 1: Delete App from Device

**Important:** You must delete and reinstall the app for entitlement changes to take effect.

1. Long-press "Just Spent" app icon on your iPhone
2. Tap "Remove App" → "Delete App"
3. Confirm deletion

### Step 2: Clean Build in Xcode

```bash
# In Xcode:
1. Product → Clean Build Folder (⇧⌘K)
2. Wait for cleaning to complete
```

### Step 3: Rebuild and Deploy

```bash
# In Xcode:
1. Select your physical device (not simulator)
2. Product → Build (⌘B)
3. Product → Run (⌘R)
4. App installs on device
```

### Step 4: Wait for Siri Indexing

**Critical:** After installing, wait **5-10 minutes** before testing.

iOS needs time to:
- Index the App Intents
- Register shortcuts with Siri
- Enable natural language processing

### Step 5: Verify in Settings

1. Open **Settings** app
2. Go to **Siri & Search**
3. Find **Just Spent**
4. Verify "Use with Ask Siri" is **ON** (toggle should be green)
5. If it shows "Something went wrong", wait longer and toggle off/on

### Step 6: Check Shortcuts App

1. Open **Shortcuts** app
2. Tap **Gallery** tab
3. Search for "Just Spent"
4. You should see:
   - "Log Expense" shortcut ✅
   - "View Expenses" shortcut ✅

If shortcuts appear in Shortcuts app, App Intents are working!

### Step 7: Test Voice Commands

**Test 1: Simple Command (Siri asks questions)**

Say: **"Hey Siri, log expense in Just Spent"**

Expected:
- Siri: "How much did you spend?"
- You: "50 dirhams"
- Siri: "What category is this expense for?"
- You: "Food"
- Siri: "Where did you make this purchase?"
- You: "Starbucks"
- Siri: "Logged د.إ 50.00 at Starbucks for Food & Dining"

**Test 2: Natural Language (All-in-one)**

Say: **"Hey Siri, I just spent 50 dirhams on food at Starbucks using Just Spent"**

Expected:
- Siri: "Logged د.إ 50.00 at Starbucks for Food & Dining"

---

## Troubleshooting Common Issues

### Issue: "Sorry, that feature isn't available" (still happens)

**Solutions:**
1. Make sure you **deleted the old app** before reinstalling
2. Wait **10 minutes** after installing (not just 5)
3. Restart your iPhone
4. Check Settings → Siri & Search → Just Spent → "Use with Ask Siri" is ON
5. Toggle Siri permission OFF then ON again

### Issue: "Something went wrong" when enabling Siri

**Solutions:**
1. Delete app completely
2. Clean build folder in Xcode (⇧⌘K)
3. Rebuild from scratch
4. Redeploy to device
5. Wait 10 minutes
6. Try enabling again

### Issue: Shortcuts don't appear in Shortcuts app

**Solutions:**
1. Force-quit Shortcuts app (swipe up from multitasking)
2. Reopen Shortcuts app
3. If still not there, restart iPhone
4. Check Xcode console for "🎤 App Shortcuts registered for Siri"

### Issue: Natural language doesn't work ("I just spent 50 dirhams")

**Solutions:**
1. This is advanced - start with simple command first
2. Make sure to include "using Just Spent" at the end
3. Natural language parsing improves over time
4. Try exact phrase: "I just spent 50 dirhams on food using Just Spent"

### Issue: Siri doesn't understand category/merchant

**Solutions:**
1. Use simple keywords: "food", "groceries", "taxi", etc.
2. Avoid complex phrases
3. Check category keyword mapping in docs
4. Say category clearly and wait for Siri to process

---

## Verification Checklist

Before reporting issues, verify:

- [ ] App was **deleted** and **reinstalled** (not just updated)
- [ ] Built from **clean build folder** (⇧⌘K)
- [ ] Deployed to **physical device** (not simulator)
- [ ] Waited **10 minutes** after install
- [ ] Settings → Siri & Search → Just Spent → "Use with Ask Siri" is **ON**
- [ ] Shortcuts app shows "Log Expense" and "View Expenses"
- [ ] Xcode console shows "🎤 App Shortcuts registered for Siri"
- [ ] Device is running **iOS 16.0+**
- [ ] Siri language is set to **English**

---

## What Changed in Fixes

| File | What Changed | Why |
|------|-------------|-----|
| **Info.plist** | Added `AppIntentsMetadata` dict | Enables App Intents framework |
| **JustSpent.entitlements** | Added `com.apple.developer.appintents-extension` | Required for App Intents support |
| **LogExpenseIntent.swift** | Added `isDiscoverable = true` | Makes intent visible to Siri |
| **ViewExpensesIntent.swift** | Added `isDiscoverable = true` | Makes intent visible to Siri |

---

## Expected Console Output

When app launches, you should see:

```
✅ Currency system initialized with 6 currencies
💱 Default currency initialized
🎤 App Shortcuts registered for Siri
```

If you don't see "🎤 App Shortcuts registered for Siri", check:
- Is `JustSpentApp.swift` calling `JustSpentShortcuts.updateAppShortcutParameters()`?
- Is the call inside the `init()` method?
- Are there any errors in the console?

---

## Still Not Working?

If after following all steps it still doesn't work:

1. **Check iOS version:**
   - Settings → General → About → Software Version
   - Must be iOS 16.0 or higher

2. **Check region/language:**
   - Settings → General → Language & Region
   - Siri works best with English (United States)

3. **Check Siri settings:**
   - Settings → Siri & Search
   - "Listen for 'Hey Siri'" must be ON
   - "Press Side Button for Siri" can be ON

4. **Try resetting Siri:**
   - Settings → Siri & Search
   - Toggle "Listen for 'Hey Siri'" OFF
   - Wait 10 seconds
   - Toggle back ON
   - Say "Hey Siri" to test

5. **Last resort - restart everything:**
   - Restart iPhone
   - Delete app
   - Clean build in Xcode
   - Rebuild
   - Redeploy
   - Wait 10 minutes
   - Test again

---

**Last Updated:** November 17, 2025
**Status:** ✅ Fixes applied, ready for testing
**Next Step:** Delete app → Clean build → Redeploy → Wait 10 min → Test
