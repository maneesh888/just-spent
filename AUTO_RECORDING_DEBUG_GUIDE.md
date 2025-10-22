# Auto-Recording Debugging Guide

## How to Test Auto-Recording Feature

### iOS Testing Steps

#### 1. **First Launch (No Auto-Recording Expected)**
```
1. Clean build and run app
2. Grant Speech Recognition permission when prompted
3. Grant Microphone permission when prompted
4. ✅ Expected: No auto-recording (first launch)
5. Check Xcode console for: "✅ First launch completed"
6. Close app completely (swipe up in app switcher)
```

#### 2. **Second Launch (Auto-Recording SHOULD Trigger)**
```
1. Tap app icon to relaunch
2. Wait ~0.5 seconds
3. ✅ Expected: Recording starts automatically
4. Check Xcode console for these messages:
   - "📱 Scene phase changed: inactive → active"
   - "🔄 App is now active"
   - "📱 onAppear: Checking auto-recording conditions"
   - "🎤 AutoRecordingCoordinator.triggerAutoRecordingIfNeeded() called"
   - "✅ All auto-recording conditions met - starting with delay"
   - "🎙️ Triggering auto-recording now"
   - "🎙️ Auto-recording triggered by coordinator"
```

#### 3. **Background/Foreground Test**
```
1. While app is running, swipe to home screen (don't close app)
2. Tap app icon to return
3. ✅ Expected: Recording starts automatically
4. Check console for: "🔄 App returned to foreground"
```

### Debug Console Output Guide

#### ✅ **Successful Auto-Recording Sequence**
```
📱 Scene phase changed: inactive → active (AppState: active)
🔄 App is now active - ContentView will check auto-recording
📱 onAppear: Checking auto-recording conditions
   - First Launch: false
   - App State: active
   - Speech Permission: true
   - Mic Permission: true
   - Recognition Available: true
🎤 AutoRecordingCoordinator.triggerAutoRecordingIfNeeded() called
   - isProcessingAutoRecord: false
   - isRecordingActive: false
   - speechRecognitionAvailable: true
   - speechPermissionGranted: true
   - microphonePermissionGranted: true
✅ All auto-recording conditions met - starting with delay
⏳ Auto-recording scheduled (delay: 0.5s)
🎙️ Triggering auto-recording now
🎙️ Auto-recording triggered by coordinator
🎙️ Recording started with auto-stop detection...
```

#### ❌ **First Launch (Expected Behavior)**
```
📱 onAppear: Checking auto-recording conditions
   - First Launch: true  ← This prevents auto-recording
⏸️ Auto-recording skipped: first launch
```

#### ❌ **Missing Permissions**
```
📱 onAppear: Checking auto-recording conditions
   - Speech Permission: false  ← Problem!
   - Mic Permission: false     ← Problem!
⏸️ Auto-recording skipped: permissions not granted
   - Speech recognition permission missing
   - Microphone permission missing
```

### Common Issues & Solutions

#### Issue 1: Auto-Recording Never Triggers
**Symptoms:** App opens but recording doesn't start

**Debug Steps:**
1. Check Xcode console output
2. Look for "First Launch: true" → Solution: This is expected on actual first launch
3. Look for permission false values → Solution: Grant permissions in Settings
4. Look for "app not active" → Solution: Scene phase issue, check logs

**Fix:**
```swift
// Check if first launch is incorrectly set
// In Xcode console, if you see "First Launch: true" on second launch:
// 1. Delete app from simulator/device
// 2. Clean build folder (Cmd+Shift+K)
// 3. Run again
```

#### Issue 2: Permissions Not Persisting
**Symptoms:** Permissions asked every time

**Fix:**
```
1. iOS Simulator: Reset permissions (Device → Erase All Content and Settings)
2. Physical Device: Delete app → Reinstall
3. Check Info.plist has correct usage descriptions
```

#### Issue 3: Scene Phase Not Changing to Active
**Symptoms:** Console shows "app not active"

**Debug:**
```swift
// Look for this in console:
"📱 Scene phase changed: inactive → active"

// If you don't see this, check:
1. WindowGroup is properly set up in JustSpentApp
2. .onChange(of: scenePhase) is attached
3. Environment objects are injected correctly
```

### Manual Testing Checklist

#### First Launch Flow
- [ ] App requests Speech Recognition permission
- [ ] App requests Microphone permission
- [ ] After granting, app shows empty state (NO auto-recording)
- [ ] Console shows "✅ First launch marked as complete"
- [ ] Close app completely

#### Second Launch Flow
- [ ] App opens
- [ ] After ~0.5 seconds, recording starts automatically
- [ ] Microphone indicator appears in status bar
- [ ] Recording button shows "Stop" (red circle)
- [ ] Console shows full auto-recording sequence

#### Background/Foreground Flow
- [ ] Recording auto-starts when returning from background
- [ ] No duplicate recordings if already recording
- [ ] Console shows "🔄 App returned to foreground"

#### Edge Cases
- [ ] Manual tap on mic button → Auto-recording skipped (already recording)
- [ ] Rapid app switching → Only one auto-recording session
- [ ] Permissions revoked → Graceful handling, no crash
- [ ] First launch without permissions → No auto-recording

### Quick Reset for Testing

```bash
# Reset UserDefaults and app state
# In Xcode console while app is running:
# This will force next launch to be treated as "first launch"

# OR delete app and reinstall:
# 1. Delete app from simulator/device
# 2. Cmd+R to build and run again
```

### Expected Behavior Summary

| Scenario | Auto-Recording? | Console Output |
|----------|----------------|----------------|
| True first launch | ❌ No | "First Launch: true" |
| Second launch | ✅ Yes | "All conditions met" |
| Return from background | ✅ Yes | "App returned to foreground" |
| Already recording | ❌ No | "already recording" |
| No permissions | ❌ No | "permissions not granted" |
| Manual recording active | ❌ No | "already recording" |

---

## Android Testing (Similar Flow)

### Logcat Filter
```
adb logcat | grep -E "(AppLifecycleManager|AutoRecordingCoordinator|MainActivity)"
```

### Expected Logcat Output
```
D/AppLifecycleManager: AppLifecycleManager initialized - First Launch: false
D/AutoRecordingCoordinator: 🎤 AutoRecordingCoordinator initialized
D/MainActivity: 📱 Activity resumed - checking auto-recording
D/AutoRecordingCoordinator: ⏳ Auto-recording scheduled (delay: 500ms)
D/AutoRecordingCoordinator: 🎙️ Triggering auto-recording now
```

---

## Final Notes

- **First launch = NO auto-recording** (by design, for user education)
- **All subsequent launches = auto-recording** (if permissions granted)
- **Debug builds have extensive logging** - Use it!
- **Release builds will have minimal logs** - Performance optimized

If auto-recording still doesn't work after following this guide, share the Xcode console output and I can diagnose the specific issue.
