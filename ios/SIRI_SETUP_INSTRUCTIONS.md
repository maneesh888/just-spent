# Siri Integration Setup Instructions

The Siri integration is not working because we need to properly set up the Intents Extension target in Xcode. Here are the exact steps to fix this:

## Quick Fix (Use NSUserActivity - Recommended for Testing)

I've already implemented an alternative approach using NSUserActivity that should work immediately:

### Steps:
1. **Build and run the app**
2. **Use the app a few times** - add some expenses manually
3. **Wait 24-48 hours** for iOS to learn patterns
4. **Try saying**: "Hey Siri, Log 25 dollars for food"

The app should now automatically create shortcuts based on usage patterns.

---

## Complete Fix (Full Intents Extension)

For full SiriKit integration, follow these manual steps in Xcode:

### 1. Add Intents Extension Target

1. Open `JustSpent.xcodeproj` in Xcode
2. Select the project in the navigator
3. Click the "+" button to add a new target
4. Choose **iOS** → **Application Extension** → **Intents Extension**
5. Product Name: `JustSpentIntents`
6. **UNCHECK** "Include UI Extension" (we don't need it)
7. Click **Finish**

### 2. Configure the Extension

1. **Delete** the auto-generated `IntentHandler.swift` in the new `JustSpentIntents` folder
2. **Drag** our existing `SiriKit/IntentHandler.swift` into the `JustSpentIntents` target
3. **Drag** the `JustSpent.intentdefinition` file to **both** targets:
   - Main app target (`JustSpent`)
   - Extension target (`JustSpentIntents`)

### 3. Set up App Groups

1. Select the **main app** target (`JustSpent`)
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **App Groups**
4. Add identifier: `group.com.justspent.shared`
5. Select the **extension** target (`JustSpentIntents`)
6. Repeat steps 2-4 for the extension

### 4. Update Extension Info.plist

Replace the content of `JustSpentIntents/Info.plist` with the one I created at:
`/ios/JustSpent/SiriKit/Info.plist`

### 5. Build Settings

For the `JustSpentIntents` target:
- **iOS Deployment Target**: 15.0 or higher
- **Swift Language Version**: Swift 5

### 6. Test the Integration

1. Build and run the main app
2. Go to **iOS Settings** → **Siri & Search** → **Just Spent**
3. Enable "Use with Siri"
4. Try saying: "Hey Siri, I just spent 25 dollars on food"

---

## Testing Commands

Once set up, try these voice commands:

### Log Expenses:
- "Hey Siri, I just spent 50 dollars on groceries"
- "Hey Siri, I paid 25 dollars for lunch"
- "Hey Siri, log 15 dollars for transportation"

### View Expenses:
- "Hey Siri, show my expenses"
- "Hey Siri, what did I spend on food?"

---

## Troubleshooting

### If Siri says "You'll need to continue in the app":
1. Check that both targets have the App Groups capability
2. Verify the Intent Definition file is added to both targets
3. Make sure the extension's bundle identifier is correct
4. Clean build folder (Cmd+Shift+K) and rebuild

### If the app doesn't open:
1. Check the URL scheme in Info.plist
2. Verify the user activity types are correctly configured
3. Make sure the main app handles `onContinueUserActivity`

### If intents aren't recognized:
1. Wait 24-48 hours for Siri to learn patterns
2. Use the app regularly to create usage patterns
3. Check iOS Settings → Siri & Search → App Shortcuts

---

## Alternative: Quick Testing with Shortcuts App

1. Open the **Shortcuts** app on iOS
2. Tap **+** to create a new shortcut
3. Add action **"Open App"** → select **Just Spent**
4. Record phrase: "Log my expense"
5. Test with: "Hey Siri, log my expense"

This will open the app when you use the voice command, and you can add expenses manually.

---

The NSUserActivity approach I've implemented should work immediately without requiring the full Intents Extension setup. Try running the app and using it for a few days - iOS will automatically suggest Siri shortcuts based on your usage patterns.