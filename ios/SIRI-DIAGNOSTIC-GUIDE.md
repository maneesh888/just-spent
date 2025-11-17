# Siri Integration Diagnostic Guide

## Understanding Your Errors

### Error 1: "Sorry, that feature isn't available, due to your device settings or region"

**What it means:**
- iOS cannot execute the Siri command
- This is **NOT** about entitlements - it's about device/region settings

**Real Causes:**
1. **Device Issue**: Siri disabled or not set up
2. **Region Issue**: Your region doesn't support Siri features
3. **Language Issue**: Siri language doesn't match app language
4. **iOS Version**: Running iOS 15 (App Intents needs iOS 16+)

### Error 2: "Something went wrong" when enabling "Use with Siri"

**What it means:**
- iOS tried to register App Intents but failed
- This is **NOT** about entitlements - it's about App Intents registration

**Real Causes:**
1. **App Intents not compiled into app bundle**
2. **Signing issue preventing intent registration**
3. **App not running on physical device**
4. **iOS needs time to index intents (wait 5-10 min)**

---

## Diagnostic Checklist

### Step 1: Verify Device Settings

**Check Siri is Enabled:**
```
Settings → Siri & Search
- "Listen for 'Hey Siri'" = ON (green)
- "Press Side Button for Siri" = ON (optional)
```

**Test Siri Works:**
```
Say: "Hey Siri, what time is it?"
If Siri doesn't respond → Fix Siri first before testing app
```

**Check Region:**
```
Settings → General → Language & Region
- Region: United States (recommended)
- Language: English (United States)
```

**Check iOS Version:**
```
Settings → General → About → Software Version
Must be: iOS 16.0 or higher (App Intents requirement)
```

### Step 2: Verify App Permissions

**Check App Permissions:**
```
Settings → Just Spent
- Siri & Search: Should be listed
- Microphone: Allow
- Speech Recognition: Allow (if available)
```

**Check Siri Permission for App:**
```
Settings → Siri & Search → Just Spent
- "Use with Ask Siri" = Should toggle ON successfully
- If it shows error → Continue to Step 3
```

### Step 3: Verify App Installation

**Check App Source:**
```
- App must be installed via Xcode (Developer mode)
- NOT via TestFlight (different signing)
- NOT via App Store (different signing)
```

**Check Device is Paired:**
```
In Xcode:
Window → Devices and Simulators
- Your iPhone should appear in list
- Status: "Connected"
- If not paired → Pair device first
```

**Check Code Signing:**
```
In Xcode:
1. Select JustSpent project
2. Select JustSpent target
3. Signing & Capabilities tab
4. Team: 3VSNLS7N3U (should match)
5. Signing Certificate: Should show valid cert
6. Provisioning Profile: Should not show error
```

### Step 4: Verify App Intents Compilation

**Check Console Output:**
```
When app launches, check Xcode console:

Expected output:
✅ Currency system initialized with 6 currencies
💱 Default currency initialized
🎤 App Shortcuts registered for Siri

If "🎤 App Shortcuts registered for Siri" is missing:
→ App Intents are NOT being registered
```

**Check App Bundle:**
```bash
# After building in Xcode:
1. Product → Show Build Folder in Finder
2. Navigate to: Products/Debug-iphoneos/JustSpent.app
3. Right-click → Show Package Contents
4. Check for: Metadata.appintents folder
   - If missing → App Intents not compiled
   - If present → App Intents compiled correctly
```

### Step 5: Verify Shortcuts App

**Check Shortcuts Visibility:**
```
Open Shortcuts app on iPhone
Tap + → Search "Just Spent"

Expected:
- "Log Expense" action appears
- "View Expenses" action appears

If nothing appears:
→ App Intents are not registered with iOS
```

---

## Solutions Based on Diagnosis

### Solution 1: Siri Not Working on Device

**Fix:**
```
1. Settings → Siri & Search
2. Toggle "Listen for 'Hey Siri'" OFF
3. Wait 5 seconds
4. Toggle "Listen for 'Hey Siri'" ON
5. Follow setup prompts
6. Test: "Hey Siri, what time is it?"
```

### Solution 2: Region/Language Issue

**Fix:**
```
1. Settings → General → Language & Region
2. Change to:
   - Region: United States
   - Language: English (United States)
3. Restart iPhone
4. Test Siri again
```

### Solution 3: iOS Version Too Old

**Fix:**
```
1. Settings → General → Software Update
2. Update to iOS 16.0 or higher
3. App Intents require iOS 16+
4. If device can't update → Use legacy SiriKit instead
```

### Solution 4: App Intents Not Registering

**Fix:**
```
1. Delete app from iPhone completely
2. In Xcode: Product → Clean Build Folder (⇧⌘K)
3. In Xcode: Select physical device (not simulator)
4. In Xcode: Product → Run (⌘R)
5. Wait for app to install
6. Check console for "🎤 App Shortcuts registered for Siri"
7. Wait 10 minutes for iOS to index
8. Open Shortcuts app to verify
```

### Solution 5: Signing/Provisioning Issue

**Fix:**
```
1. In Xcode: JustSpent target → Signing & Capabilities
2. Uncheck "Automatically manage signing"
3. Wait 2 seconds
4. Re-check "Automatically manage signing"
5. Xcode will regenerate provisioning profile
6. Clean build folder (⇧⌘K)
7. Rebuild (⌘B)
8. Redeploy (⌘R)
```

### Solution 6: Metadata.appintents Missing

**Fix:**
```
If App Intents folder is missing from app bundle:

1. Check AppIntents files are added to target:
   - Select LogExpenseIntent.swift in Xcode
   - Right sidebar → Target Membership
   - "JustSpent" should be checked ✓

2. Repeat for ViewExpensesIntent.swift and AppShortcutsProvider.swift

3. Clean build (⇧⌘K)
4. Rebuild (⌘B)
5. Check build folder again for Metadata.appintents
```

---

## What the Errors Really Mean

### "Feature isn't available due to region"

**NOT an app issue, it's a device/region issue:**
- ✅ Fix by changing region to US in Settings
- ✅ Fix by ensuring Siri is enabled and working
- ✅ Fix by updating iOS to 16+
- ❌ NOT fixed by changing entitlements
- ❌ NOT fixed by changing Info.plist

### "Something went wrong" when enabling shortcuts

**NOT an entitlement issue, it's a registration issue:**
- ✅ Fix by waiting 10 minutes after install
- ✅ Fix by clean build + redeploy
- ✅ Fix by ensuring App Intents are compiled
- ✅ Fix by checking code signing is valid
- ❌ NOT fixed by adding fake entitlements
- ❌ NOT fixed by adding meaningless plist keys

---

## What I Removed (Incorrect Fixes)

### ❌ Removed: `com.apple.developer.appintents-extension`
**Why:** This is for App Intents **extensions** (separate targets), not for main app using App Intents directly.

**App Intents in main app DO NOT need special entitlements beyond:**
- `com.apple.developer.siri` (already present)
- `com.apple.security.application-groups` (already present)

### ✅ What Actually Matters:

**Info.plist:**
- `NSAppIntentsUsageDescription` ✓ (already present)
- `NSSiriUsageDescription` ✓ (already present)
- `NSMicrophoneUsageDescription` ✓ (already present)
- `AppIntentsMetadata` ✓ (added for metadata)

**Entitlements:**
- `com.apple.developer.siri` ✓ (already present)
- `com.apple.security.application-groups` ✓ (already present)

**Code:**
- `LogExpenseIntent: AppIntent` ✓ (present)
- `ViewExpensesIntent: AppIntent` ✓ (present)
- `JustSpentShortcuts: AppShortcutsProvider` ✓ (present)
- `JustSpentShortcuts.updateAppShortcutParameters()` ✓ (called in app init)

---

## Next Steps

1. **Run Diagnostic Checklist** (above)
2. **Identify which solution applies** to your specific error
3. **Apply the correct fix** (not fake entitlements)
4. **Test on physical device** (Siri doesn't work in simulator)
5. **Report back** with console output and Shortcuts app status

---

**Important:** The errors you're seeing are **device/region configuration issues** or **App Intents registration timing issues**, NOT entitlement or capability issues. The app code is correct - focus on device settings and deployment process.

---

**Last Updated:** November 17, 2025
**Status:** Ready for proper diagnosis
