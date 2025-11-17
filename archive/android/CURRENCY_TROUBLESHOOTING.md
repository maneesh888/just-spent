# Currency.kt Troubleshooting Guide

## Common Errors and Fixes

### Error 1: "Unresolved reference: Currency" in other files

**Cause**: Currency system not initialized before use

**Fix**: Ensure `Currency.initialize(context)` is called in Application.onCreate()

```kotlin
// In JustSpentApplication.kt
class JustSpentApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Currency.initialize(this)  // ← Add this line
    }
}
```

### Error 2: "IllegalStateException: Currency system not initialized"

**Cause**: Trying to access `Currency.all` or `Currency.common` before initialization

**Fix**: Always initialize in Application.onCreate() or test setup

```kotlin
// In tests
@Before
fun setup() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    Currency.initialize(context)
}
```

### Error 3: "FileNotFoundException: currencies.json"

**Cause**: Missing currencies.json file in assets folder

**Fix**: Verify file exists at correct location

**Check:**
```bash
ls -la android/app/src/main/assets/currencies.json
```

**If missing**, copy from shared folder:
```bash
cp shared/currencies.json android/app/src/main/assets/
```

### Error 4: "SerializationException" when loading currencies

**Cause**: JSON structure doesn't match Currency data class

**Fix**: Verify currencies.json structure matches this format:

```json
{
  "version": "2.0",
  "lastUpdated": "2025-01-29",
  "currencies": [
    {
      "code": "AED",
      "symbol": "د.إ",
      "displayName": "UAE Dirham",
      "shortName": "Dirham",
      "localeIdentifier": "ar_AE",
      "isRTL": true,
      "voiceKeywords": ["aed", "dirham", "dirhams"]
    }
  ]
}
```

### Error 5: "Unresolved reference: kotlinx.serialization"

**Cause**: Missing Kotlin serialization dependency

**Fix**: Add to `app/build.gradle.kts`:

```kotlin
plugins {
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0"
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
}
```

### Error 6: Red underlines in Android Studio but code compiles

**Cause**: Android Studio cache issues

**Fix**: Invalidate caches and restart

1. File → Invalidate Caches...
2. Check "Invalidate and Restart"
3. Click "Invalidate and Restart"

### Error 7: "Cannot access 'Currency'" in Compose

**Cause**: Not importing Currency class

**Fix**: Add import

```kotlin
import com.justspent.app.data.model.Currency
```

### Error 8: NullPointerException when accessing Currency.AED

**Cause**: Currency system not initialized before accessing legacy references

**Fix**: Initialize Currency first

```kotlin
// Wrong
val currency = Currency.AED  // NPE if not initialized

// Right
Currency.initialize(context)
val currency = Currency.AED  // Works
```

## Specific Error Messages

### "Expecting a top level declaration" at line 142

**Cause**: Nested function `matchesKeyword` inside `detectFromText`

**Fix**: This is valid Kotlin syntax. Ensure you're using Kotlin 1.8+

Check `build.gradle.kts`:
```kotlin
kotlin {
    jvmToolchain(17)
}
```

### "Type mismatch: inferred type is String but Regex was expected"

**Cause**: Incorrect regex construction

**Current code (correct)**:
```kotlin
return text.contains(Regex("\\b${Regex.escape(lowercaseKeyword)}\\b"))
```

### "Smart cast to 'Currency' is impossible"

**Cause**: Nullable return from `fromCode()`

**Fix**: Use safe call or !! operator

```kotlin
// Safe call
val currency = Currency.fromCode("USD")
currency?.let { /* use it */ }

// Non-null assertion (only if you're sure it exists)
val currency = Currency.fromCode("USD")!!
```

## Build Configuration Issues

### Missing asset files after build

**Cause**: Assets not properly configured in build

**Fix**: Verify `build.gradle.kts` has:

```kotlin
android {
    sourceSets {
        getByName("main") {
            assets.srcDirs("src/main/assets")
        }
    }
}
```

### Clean and rebuild

```bash
cd android
./gradlew clean
./gradlew assembleDebug
```

## Testing Issues

### Robolectric can't find currencies.json

**Cause**: Missing robolectric.properties

**Fix**: Create `app/src/test/resources/robolectric.properties`:

```properties
sdk=28
```

### Tests fail with "Currency system not initialized"

**Fix**: Add @Before setup in every test class

```kotlin
@Before
fun setup() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    Currency.initialize(context)
}
```

## How to Diagnose Your Specific Error

### Step 1: Find the exact error message

Look in Android Studio's "Build" or "Problems" panel for the exact error text.

### Step 2: Check error location

Note which line number and what code is highlighted in red.

### Step 3: Common patterns

| Error Pattern | Likely Cause | Fix |
|---------------|--------------|-----|
| Red underline on `Currency` | Import missing | Add import |
| Red underline on `Currency.all` | Not initialized | Call initialize() |
| Red underline on `detectFromText` | Function syntax | Update Kotlin version |
| Red underline on `matchesKeyword` | Nested function | Valid in Kotlin 1.8+ |
| Entire file red | Plugin issue | Sync Gradle |

### Step 4: Quick fixes

1. **Sync Gradle**: File → Sync Project with Gradle Files
2. **Clean Build**: Build → Clean Project, then Build → Rebuild Project
3. **Restart IDE**: File → Invalidate Caches → Invalidate and Restart
4. **Check imports**: Ensure all imports at top of file are resolved

## Still Having Issues?

Please provide:
1. **Exact error message** from Android Studio
2. **Line number** where error occurs
3. **Screenshot** of the error (if possible)
4. **Android Studio version**
5. **Kotlin version** (from build.gradle.kts)

Common error locations to check:
- Line 142-152: `matchesKeyword` function (nested function syntax)
- Line 155-168: `findMatch` function (nested function syntax)
- Line 180-185: Legacy currency references (need initialization)
- Line 203: JSON deserialization (check dependencies)

## Quick Verification

Run these commands to verify setup:

```bash
# 1. Check file exists
ls -la android/app/src/main/assets/currencies.json

# 2. Check file is valid JSON
cat android/app/src/main/assets/currencies.json | python3 -m json.tool > /dev/null && echo "✅ JSON Valid" || echo "❌ JSON Invalid"

# 3. Count currencies
grep -o '"code"' android/app/src/main/assets/currencies.json | wc -l
# Should show: 36

# 4. Verify tests can find it
cd android
./gradlew testDebugUnitTest --tests "com.justspent.app.data.model.CurrencyTest" -i
```

---

**If you provide the specific error message(s) you're seeing, I can give you a precise fix!**
