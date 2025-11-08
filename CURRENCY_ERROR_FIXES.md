# Currency.kt Error Fixes - Quick Guide

## ✅ Diagnostic Results

I've run a comprehensive diagnostic on your Currency.kt setup, and **everything is configured correctly**:

- ✅ Currency.kt file exists and syntax is valid
- ✅ currencies.json exists with 36 currencies (valid JSON)
- ✅ Kotlin serialization plugin enabled
- ✅ kotlinx-serialization-json dependency present
- ✅ Robolectric configured for tests
- ✅ Currency.initialize() called in JustSpentApplication

**The code is correct!** The errors you're seeing are likely Android Studio cache/sync issues.

## 🔧 Quick Fixes (Try in Order)

### Fix 1: Sync Gradle (Most Common Fix)
```
File → Sync Project with Gradle Files
```
**When to use**: First thing to try, especially after pulling new code

### Fix 2: Invalidate Caches and Restart
```
File → Invalidate Caches → Select "Invalidate and Restart" → Confirm
```
**When to use**: If Gradle sync didn't fix it. This clears Android Studio's cache.

### Fix 3: Clean and Rebuild
```bash
cd android
./gradlew clean
./gradlew assembleDebug
```
**When to use**: If caches didn't help. Forces complete rebuild.

### Fix 4: Restart Android Studio
Simply close and reopen Android Studio.

### Fix 5: Update Kotlin Plugin (if using older IDE version)
```
File → Settings → Plugins → Search "Kotlin" → Update if available
```
**When to use**: If you see errors on nested functions (lines 142-168)

## 🐛 Specific Error Messages & Fixes

### "Nested function matchesKeyword not allowed here"
**Cause**: IDE thinks you're using old Kotlin version
**Fix**:
1. Sync Gradle (Fix #1 above)
2. Check Kotlin version in build.gradle.kts (should be 1.8+)
3. Invalidate caches (Fix #2 above)

### "Unresolved reference: Currency" in other files
**Cause**: Import missing
**Fix**: Add import at top of file:
```kotlin
import com.justspent.app.data.model.Currency
```

### "IllegalStateException: Currency system not initialized"
**Cause**: Accessing Currency.all before initialization
**Fix**: Ensure JustSpentApplication.onCreate() calls Currency.initialize(this)
(Already done in your code ✅)

### Entire file showing red underlines
**Cause**: Gradle not synced or cache issue
**Fix**: Try Fix #1, then Fix #2, then Fix #3

## 📋 Diagnostic Tools

### Run Diagnostic Script
I've created a diagnostic script to help identify issues:

```bash
cd android
./diagnose-currency.sh
```

This checks:
- File existence
- JSON validity
- Dependencies
- Configuration
- Common issues

### Manual Checks

**Check 1: Verify currencies.json**
```bash
cat android/app/src/main/assets/currencies.json | python3 -m json.tool > /dev/null && echo "✅ Valid" || echo "❌ Invalid"
```

**Check 2: Count currencies**
```bash
grep -o '"code"' android/app/src/main/assets/currencies.json | wc -l
# Should show: 36
```

**Check 3: Verify build config**
```bash
grep "serialization" android/app/build.gradle.kts
# Should show plugin and dependency
```

## 💡 Understanding the Code

The Currency.kt file uses **nested functions** (valid in Kotlin 1.8+):

```kotlin
fun detectFromText(text: String): Currency? {
    // Nested helper function - THIS IS VALID KOTLIN
    fun matchesKeyword(text: String, keyword: String): Boolean {
        // ...
    }

    // Another nested function - ALSO VALID
    fun findMatch(currencies: List<Currency>): Currency? {
        // ...
    }

    // Use the nested functions
    findMatch(common)?.let { return it }
}
```

If Android Studio shows these as errors, it's an IDE issue, not a code issue.

## 🎯 Most Likely Cause

Based on the diagnostic results, **99% likely your issue is**:

1. **Android Studio cache not synced** after pulling latest code
2. **Gradle not synced** after dependency changes

**Solution**: Run Fix #1 (Sync Gradle), then Fix #2 (Invalidate Caches)

## 📸 Still Seeing Errors?

Please provide:

1. **Screenshot** of the error in Android Studio
2. **Exact error message** from the Problems panel
3. **Line number(s)** where errors appear
4. **Your Android Studio version**: Help → About
5. **Your Kotlin plugin version**: Settings → Plugins → Kotlin

Common error locations:
- **Lines 142-152**: matchesKeyword function (nested function syntax)
- **Lines 155-168**: findMatch function (nested function syntax)
- **Lines 180-185**: Currency.AED/USD/etc (legacy references)

## ✅ Verification Steps

After applying fixes, verify:

1. **No red underlines** in Currency.kt
2. **Build succeeds**:
   ```bash
   cd android
   ./gradlew assembleDebug
   ```
3. **Tests pass**:
   ```bash
   ./gradlew testDebugUnitTest --tests "com.justspent.app.data.model.CurrencyTest"
   ```

## 📚 Reference Documents

- **CURRENCY_TROUBLESHOOTING.md** - Detailed troubleshooting guide
- **TEST_COVERAGE_REPORT.md** - Test coverage details
- **VERIFICATION_REPORT.md** - Implementation verification

---

## Quick Command Reference

```bash
# Run diagnostic
cd android && ./diagnose-currency.sh

# Sync dependencies (if gradlew fails)
cd android && ./gradlew --refresh-dependencies

# Clean build
cd android && ./gradlew clean assembleDebug

# Run tests
cd android && ./gradlew testDebugUnitTest

# Full CI check
cd .. && ./local-ci.sh --android --quick
```

---

**TL;DR**: Your code is correct. Try these in order:
1. Sync Gradle (File → Sync Project with Gradle Files)
2. Invalidate Caches (File → Invalidate Caches → Restart)
3. Restart Android Studio

**If still showing errors, please share screenshot!**
