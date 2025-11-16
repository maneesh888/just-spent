# Google Assistant Integration Testing Guide for Just Spent (Android)

## Overview

This guide helps you test and troubleshoot Google Assistant integration for voice expense logging in the Just Spent Android app.

## Prerequisites

Before testing Google Assistant integration, ensure you have:

- ✅ Android device with Google Assistant enabled
- ✅ Google Play Services installed and updated
- ✅ Just Spent app installed on the device
- ✅ Microphone permissions granted
- ✅ Google Assistant permissions granted
- ✅ App Actions Test Tool installed (recommended)

## Table of Contents

1. [Testing Methods](#testing-methods)
2. [Using App Actions Test Tool](#using-app-actions-test-tool)
3. [Testing with Real Google Assistant](#testing-with-real-google-assistant)
4. [Supported Voice Commands](#supported-voice-commands)
5. [Troubleshooting](#troubleshooting)
6. [Deep Link Testing](#deep-link-testing)

---

## Testing Methods

There are three ways to test Google Assistant integration:

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| **App Actions Test Tool** | Development | Fast, no waiting for indexing | Requires installation |
| **ADB Deep Link** | Quick testing | Simple, no dependencies | Manual command |
| **Real Google Assistant** | Production | Real user experience | Requires app indexing |

---

## Using App Actions Test Tool

### 1. Install App Actions Test Tool

```bash
# Download from Google
# https://developers.google.com/assistant/app/test-tool

# Or install via ADB
adb install app-actions-test-tool.apk
```

### 2. Configure the Tool

1. Open **App Actions Test Tool**
2. Select **Just Spent** from the app list
3. The tool will automatically detect your `actions.xml` configuration

### 3. Test Voice Commands

#### Test Case 1: Simple Expense
```
Input: "I spent 50 dirhams on groceries"

Expected Flow:
1. Test tool triggers deep link: https://justspent.app/expense?command=I%20spent%2050%20dirhams%20on%20groceries
2. VoiceDeepLinkActivity opens
3. VoiceCommandProcessor extracts:
   - Amount: 50
   - Currency: AED (dirhams)
   - Category: Grocery
4. UI shows confirmation or auto-saves (if high confidence)
5. Expense appears in app
```

#### Test Case 2: Structured Intent
```
Input: Use "CREATE_MONEY_TRANSFER" action
Parameters:
- moneyTransfer.amount.value: 100
- moneyTransfer.amount.currency: USD
- moneyTransfer.category: Food & Dining
- merchant.name: Starbucks

Expected Flow:
1. Deep link: https://justspent.app/expense?amount=100&currency=USD&category=Food%20%26%20Dining&merchant=Starbucks
2. VoiceDeepLinkActivity opens
3. Structured data path processes params directly
4. Expense saved with high confidence
```

#### Test Case 3: Quick Add Shortcut
```
Input: Use "add_expense_voice" shortcut

Expected Flow:
1. VoiceDeepLinkActivity opens
2. Voice recording automatically starts (if autoStartRecording=true)
3. User speaks expense
4. Processing happens as usual
```

### 4. Verify Results

After each test:
- [ ] Check if VoiceDeepLinkActivity opened
- [ ] Verify expense data extraction
- [ ] Check confidence score
- [ ] Confirm expense was saved to database
- [ ] Verify expense appears in main expense list

---

## Testing with Real Google Assistant

### 1. Enable Google Assistant

```bash
# Ensure Google app is updated
# Ensure device locale is set correctly
# Enable "Hey Google" detection
```

### 2. App Indexing (Required)

**IMPORTANT**: Google Assistant needs to index your app before recognizing it.

**Options for App Indexing:**

#### Option A: Upload to Play Store (Recommended)
1. Upload app to Play Store (internal testing track)
2. Install from Play Store on test device
3. Wait 24-48 hours for Google to index
4. Test with real voice commands

#### Option B: Use App Actions Test Tool
- Simulates indexed state without publishing
- See "Using App Actions Test Tool" section above

#### Option C: Firebase App Indexing (Advanced)
```kotlin
// Add Firebase App Indexing SDK
implementation 'com.google.firebase:firebase-appindexing:20.0.0'

// Index actions programmatically
FirebaseAppIndex.getInstance().update(/* index definition */)
```

### 3. Test Voice Commands

Once indexed, try these commands:

```
"Hey Google, log 50 dirhams for groceries in Just Spent"
"Ok Google, I spent 100 dollars on shopping"
"Hey Google, add expense in Just Spent"
"Ok Google, open Just Spent and add expense"
```

### 4. What Happens

**Success Flow:**
1. Google Assistant recognizes intent
2. Matches to Just Spent actions
3. Extracts parameters
4. Triggers deep link
5. App opens and processes

**Failure Scenarios:**
- "I don't understand" → App not indexed or phrasing not recognized
- "You'll need to continue in the app" → Deep link failed
- Wrong app opens → Multiple apps with similar actions

---

## Supported Voice Commands

### Pattern 1: Natural Language (Best for Users)
```
"I spent [amount] [currency] on [category]"
"I just spent [amount] at [merchant]"
"Log [amount] for [category]"
"I paid [amount] [currency] for [item]"

Examples:
✅ "I spent 50 dirhams on groceries"
✅ "I just spent 100 dollars at Starbucks"
✅ "Log 25 euros for lunch"
✅ "I paid 500 rupees for shopping"
```

### Pattern 2: Explicit Intent
```
"Log expense in Just Spent"
"Add expense in Just Spent"
"Record expense in Just Spent"

→ Opens voice expense dialog
```

### Pattern 3: Shortcut Phrases
```
"Coffee time"
"Lunch expense"
"Gas fill up"

→ If shortcuts are trained
```

### Pattern 4: Direct Open
```
"Open Just Spent"
"Launch Just Spent"

→ Opens main app
```

---

## Deep Link Testing

### Manual Deep Link Testing via ADB

Test deep links directly without Google Assistant:

#### Test 1: Natural Language Command
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?command=I%20spent%2050%20dirhams%20on%20groceries" \
  com.justspent.app
```

**Expected**: VoiceDeepLinkActivity opens, processes command, shows expense details

#### Test 2: Structured Data
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?amount=100&currency=USD&category=Food%20%26%20Dining&merchant=Starbucks" \
  com.justspent.app
```

**Expected**: VoiceDeepLinkActivity opens, uses structured data path, high confidence save

#### Test 3: Currency Parameter
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?amount=50&currency=AED&category=Grocery" \
  com.justspent.app
```

**Expected**: Expense saved with AED currency, not default currency

#### Test 4: Custom Scheme
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "justspent://expense?amount=25&category=Food" \
  com.justspent.app
```

**Expected**: VoiceDeepLinkActivity opens via custom scheme

#### Test 5: View Intent
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://justspent.app/view?period=today&category=Food" \
  com.justspent.app
```

**Expected**: Main app opens, filtered by today + Food category (if implemented)

---

## Troubleshooting

### Issue 1: "Sorry, I don't understand"

**Causes:**
- App not indexed by Google
- Voice command doesn't match intent patterns
- Google Assistant language mismatch

**Solutions:**
1. ✅ Use App Actions Test Tool for testing without indexing
2. ✅ Ensure app is installed from Play Store (internal testing track)
3. ✅ Wait 24-48 hours after first installation
4. ✅ Try exact phrases from documentation
5. ✅ Check device locale matches app's supported languages

### Issue 2: "You'll need to continue in the app"

**Causes:**
- Deep link not configured correctly
- App not exported in manifest
- Intent filter missing
- SSL certificate verification failed

**Solutions:**
```bash
# Verify deep link configuration
adb shell dumpsys package com.justspent.app | grep -A 20 "Intent Filter"

# Check if VoiceDeepLinkActivity is exported
# Should show: android:exported=true
adb shell dumpsys package com.justspent.app | grep VoiceDeepLinkActivity

# Test deep link manually
adb shell am start -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?amount=50" \
  com.justspent.app
```

**Checklist:**
- [ ] VoiceDeepLinkActivity has `android:exported="true"` in manifest
- [ ] Intent filter includes `android.intent.action.VIEW`
- [ ] Intent filter includes `android.intent.category.BROWSABLE`
- [ ] Deep link domain matches `actions.xml` (justspent.app)
- [ ] App verification enabled: `android:autoVerify="true"`

### Issue 3: Wrong App Opens

**Causes:**
- Multiple apps with similar deep link schemes
- Conflicting intent filters

**Solutions:**
1. Clear default app associations:
```bash
adb shell pm clear-default-for-app com.justspent.app
```

2. Make your app the default handler:
```bash
adb shell pm set-app-link com.justspent.app 0
```

3. Verify intent filter priority in manifest

### Issue 4: Parameters Not Extracted

**Causes:**
- URL encoding issues
- Query parameter names mismatch
- VoiceCommandProcessor regex failures

**Solutions:**
1. Test with URL-encoded commands:
```bash
# Instead of spaces, use %20
# Instead of &, use %26
adb shell am start -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?command=I%20spent%2050%20dirhams%20on%20groceries" \
  com.justspent.app
```

2. Check logcat for parsing errors:
```bash
adb logcat | grep VoiceCommandProcessor
adb logcat | grep VoiceDeepLinkActivity
```

3. Verify parameter names match between:
   - `actions.xml` → `urlParameter` names
   - `VoiceDeepLinkActivity.kt` → `uri.getQueryParameter()` names

### Issue 5: Confidence Score Always Low

**Causes:**
- VoiceCommandProcessor not recognizing patterns
- Currency not detected
- Category keywords not matching

**Solutions:**
1. Check logs:
```bash
adb logcat | grep "Confidence score"
adb logcat | grep "Extracted:"
```

2. Add more keywords to `VoiceCommandProcessor.kt`:
```kotlin
// In categoryKeywords map
"food & dining" to listOf(
    "food", "tea", "coffee", "lunch", "dinner", "breakfast",
    "meal", "snack", "restaurant", "cafe", "starbucks", // Add more
)
```

3. Test with explicit currency:
```bash
# Instead of: "I spent 50 on groceries"
# Use: "I spent 50 dirhams on groceries"
```

### Issue 6: Microphone Permission Issues

**Causes:**
- Permission not granted
- Permission revoked
- Permission request not triggered

**Solutions:**
```bash
# Grant permission manually
adb shell pm grant com.justspent.app android.permission.RECORD_AUDIO
adb shell pm grant com.justspent.app android.permission.MODIFY_AUDIO_SETTINGS

# Check permission status
adb shell dumpsys package com.justspent.app | grep permission

# Reset all permissions
adb shell pm reset-permissions
```

---

## Verification Checklist

Before reporting issues, verify:

### Configuration
- [ ] `actions.xml` exists in `/res/xml/`
- [ ] `shortcuts.xml` exists in `/res/xml/`
- [ ] `strings.xml` has shortcut labels
- [ ] Manifest has App Actions metadata
- [ ] Manifest has shortcuts metadata
- [ ] VoiceDeepLinkActivity is exported
- [ ] Intent filters include HTTPS scheme
- [ ] Intent filters include custom scheme
- [ ] Auto-verify enabled for HTTPS

### Permissions
- [ ] RECORD_AUDIO permission declared in manifest
- [ ] MODIFY_AUDIO_SETTINGS permission declared
- [ ] ASSISTANT permission declared
- [ ] Microphone permission granted at runtime
- [ ] Assistant permission granted at runtime

### Build & Install
- [ ] App builds without errors
- [ ] App installs on device
- [ ] No ProGuard issues with voice classes
- [ ] Dependencies correctly configured

### Testing
- [ ] ADB deep link test works
- [ ] App Actions Test Tool recognizes app
- [ ] Voice recording works manually in app
- [ ] Expense saves correctly via manual entry

---

## Advanced Testing

### Test Voice Command Processor Directly

```kotlin
// In Android Studio or test code
val processor = VoiceCommandProcessor()
val defaultCurrency = Currency.AED

val result = processor.extractExpenseData(
    voiceInput = "I spent 50 dirhams on groceries",
    defaultCurrency = defaultCurrency
)

println("Amount: ${result.amount}")
println("Currency: ${result.currency}")
println("Category: ${result.category}")
println("Confidence: ${result.confidenceScore}")
```

### Monitor Google Assistant Logs

```bash
# Filter for Assistant-related logs
adb logcat | grep "Assistant"
adb logcat | grep "AppActions"
adb logcat | grep "DeepLink"

# Save logs to file
adb logcat -d > assistant_logs.txt
```

### Test Different Locales

```bash
# Change device locale
adb shell setprop persist.sys.locale ar-AE  # Arabic (UAE)
adb shell setprop persist.sys.locale en-US  # English (US)
adb shell setprop persist.sys.locale en-GB  # English (UK)

# Restart app
adb shell am force-stop com.justspent.app
adb shell am start com.justspent.app/.MainActivity
```

---

## Expected Behavior Summary

| Scenario | Expected Result |
|----------|----------------|
| **ADB Deep Link** | Immediate app launch with parameters |
| **App Actions Test Tool** | Recognition + deep link trigger |
| **Real Assistant (indexed)** | Voice → Intent → Deep Link → App |
| **Real Assistant (not indexed)** | "Sorry, I don't understand" |
| **High Confidence (>80%)** | Auto-save without confirmation |
| **Low Confidence (<80%)** | Show confirmation dialog |
| **Missing Amount** | Error message with training suggestions |
| **Missing Currency** | Uses default currency (e.g., AED) |
| **Unknown Category** | Defaults to "Other" category |

---

## Next Steps After Testing

### If Everything Works
1. ✅ Document successful voice patterns
2. ✅ Train users with example phrases
3. ✅ Monitor analytics for success rates
4. ✅ Collect feedback for phrase improvements

### If Issues Found
1. 🔍 Check troubleshooting section above
2. 📝 Review logs with `adb logcat`
3. 🧪 Test with simpler commands first
4. 💬 Contact support with logs

---

## Resources

- [Google Assistant App Actions Documentation](https://developers.google.com/assistant/app)
- [App Actions Test Tool](https://developers.google.com/assistant/app/test-tool)
- [Android Deep Linking Guide](https://developer.android.com/training/app-links)
- [Just Spent Voice Integration Docs](../android-assistant-integration.md)

---

**Last Updated**: 2025-11-16
**Version**: 1.0
**Maintainer**: Just Spent Development Team
