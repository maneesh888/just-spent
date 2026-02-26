#!/bin/bash

# Currency.kt Diagnostic Script
# Run this to diagnose issues with Currency.kt

echo "🔍 Currency.kt Diagnostic Tool"
echo "================================"
echo

# Check 1: File exists
# Ensure we are in the android directory
cd "$(dirname "$0")/../../android" || exit 1

echo "✓ Checking Currency.kt exists..."
if [ -f "app/src/main/java/com/justspent/app/data/model/Currency.kt" ]; then
    echo "  ✅ Currency.kt found"
else
    echo "  ❌ Currency.kt NOT FOUND"
    exit 1
fi
echo

# Check 2: currencies.json exists
echo "✓ Checking currencies.json exists..."
if [ -f "app/src/main/assets/currencies.json" ]; then
    echo "  ✅ currencies.json found"

    # Validate JSON
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool app/src/main/assets/currencies.json > /dev/null 2>&1; then
            echo "  ✅ JSON is valid"
        else
            echo "  ❌ JSON is INVALID - syntax error"
            exit 1
        fi
    fi

    # Count currencies
    count=$(grep -o '"code"' app/src/main/assets/currencies.json | wc -l)
    echo "  ✅ Contains $count currencies"

    if [ "$count" -eq 36 ]; then
        echo "  ✅ Correct count (36 currencies)"
    else
        echo "  ⚠️  Expected 36, found $count"
    fi
else
    echo "  ❌ currencies.json NOT FOUND"
    echo "  Fix: cp ../shared/currencies.json app/src/main/assets/"
    exit 1
fi
echo

# Check 3: Serialization plugin
echo "✓ Checking Kotlin serialization plugin..."
if grep -q "org.jetbrains.kotlin.plugin.serialization" app/build.gradle.kts; then
    echo "  ✅ Serialization plugin enabled"
else
    echo "  ❌ Serialization plugin MISSING in build.gradle.kts"
    exit 1
fi
echo

# Check 4: Serialization dependency
echo "✓ Checking kotlinx-serialization-json dependency..."
if grep -q "kotlinx-serialization-json" app/build.gradle.kts; then
    echo "  ✅ Serialization dependency found"
else
    echo "  ❌ kotlinx-serialization-json MISSING from dependencies"
    exit 1
fi
echo

# Check 5: Check for syntax issues in Currency.kt
echo "✓ Checking Currency.kt syntax..."

# Check for nested functions (valid in Kotlin 1.8+)
if grep -q "fun matchesKeyword" app/src/main/java/com/justspent/app/data/model/Currency.kt; then
    echo "  ✅ matchesKeyword function found (nested function)"
fi

if grep -q "fun findMatch" app/src/main/java/com/justspent/app/data/model/Currency.kt; then
    echo "  ✅ findMatch function found (nested function)"
fi

# Check for proper imports
if grep -q "import kotlinx.serialization.Serializable" app/src/main/java/com/justspent/app/data/model/Currency.kt; then
    echo "  ✅ Serialization import found"
else
    echo "  ❌ Missing: import kotlinx.serialization.Serializable"
fi

if grep -q "import android.content.Context" app/src/main/java/com/justspent/app/data/model/Currency.kt; then
    echo "  ✅ Context import found"
else
    echo "  ❌ Missing: import android.content.Context"
fi
echo

# Check 6: Robolectric configuration for tests
echo "✓ Checking test configuration..."
if [ -f "app/src/test/resources/robolectric.properties" ]; then
    echo "  ✅ robolectric.properties exists"
    cat app/src/test/resources/robolectric.properties
else
    echo "  ⚠️  robolectric.properties missing (needed for tests)"
    echo "  Create: app/src/test/resources/robolectric.properties with content 'sdk=28'"
fi
echo

# Check 7: Application initialization
echo "✓ Checking Currency.initialize() call..."
if [ -f "app/src/main/java/com/justspent/app/JustSpentApplication.kt" ]; then
    if grep -q "Currency.initialize" app/src/main/java/com/justspent/app/JustSpentApplication.kt; then
        echo "  ✅ Currency.initialize() called in JustSpentApplication"
    else
        echo "  ⚠️  Currency.initialize() NOT called in Application.onCreate()"
        echo "  Add: Currency.initialize(this) in JustSpentApplication.onCreate()"
    fi
else
    echo "  ⚠️  JustSpentApplication.kt not found"
fi
echo

echo "================================"
echo "📊 Summary"
echo "================================"
echo

# Quick fix suggestions
echo "💡 Quick Fixes (if you see errors in Android Studio):"
echo
echo "1. Sync Gradle:"
echo "   File → Sync Project with Gradle Files"
echo
echo "2. Invalidate Caches:"
echo "   File → Invalidate Caches → Invalidate and Restart"
echo
echo "3. Clean Build:"
echo "   ./gradlew clean"
echo "   ./gradlew assembleDebug"
echo
echo "4. Restart Android Studio"
echo

# Check if we can provide more specific help
echo "❓ Still seeing errors?"
echo
echo "Please share:"
echo "  • Exact error message from Android Studio"
echo "  • Line number where error occurs"
echo "  • Screenshot of the error (if possible)"
echo
echo "Most common issues:"
echo "  • Line 142-152: Nested functions (valid in Kotlin 1.8+, ensure IDE knows)"
echo "  • Line 180-185: Currency.AED etc. (need initialization first)"
echo "  • Entire file: Red (need Gradle sync)"
echo

echo "✅ Diagnostic complete!"
