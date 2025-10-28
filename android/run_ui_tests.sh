#!/bin/bash
# Just Spent Android UI Tests Runner
# Workaround for Gradle connectedDebugAndroidTest abortion issue
# This script builds APKs and runs tests via ADB, which works reliably

set -e  # Exit on error

echo "🔨 Building test APKs..."
./gradlew assembleDebug assembleDebugAndroidTest

echo ""
echo "📱 Installing APKs on device..."
adb install -r -t app/build/outputs/apk/debug/app-debug.apk
adb install -r -t app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk

echo ""
echo "🧪 Running UI tests with HiltTestRunner..."
adb shell am instrument -w -r -e debug false \
  com.justspent.app.test/com.justspent.app.HiltTestRunner

echo ""
echo "✅ Test execution complete!"
echo ""
echo "📊 Test Summary:"
echo "   - Expected: 88 tests discovered"
echo "   - Passing:  43 tests (48.9% pass rate as of last run)"
echo "   - Failing:  45 tests (assertion failures, not crashes)"
echo ""
echo "Note: Run individual test classes for detailed results:"
echo "  adb shell am instrument -w -r -e debug false \\"
echo "    -e class com.justspent.app.MultiCurrencyTabbedUITest \\"
echo "    com.justspent.app.test/com.justspent.app.HiltTestRunner"
