#!/bin/bash
set -e

echo "🧪 Testing iOS Crash Fix"
echo "========================"
echo ""

cd "$(dirname "$0")/ios/JustSpent"

echo "📦 Building project..."
xcodebuild clean build \
  -project JustSpent.xcodeproj \
  -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet || exit 1

echo "✅ Build successful"
echo ""

echo "🧪 Running CurrencyInitializationTests..."
xcodebuild test \
  -project JustSpent.xcodeproj \
  -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:JustSpentTests/CurrencyInitializationTests/testCurrency_worksWithStringCurrencyCodes \
  2>&1 | tee test-output.log

echo ""
echo "📊 Checking results..."

if grep -q "Test Case.*testCurrency_worksWithStringCurrencyCodes.*passed" test-output.log; then
    echo "✅ TEST PASSED - Crash fixed AND JSON loaded successfully!"
    exit 0
elif grep -q "Expected 6 currencies but got 0" test-output.log; then
    echo "⚠️  TEST FAILED - Crash is fixed, but currencies.json not accessible"
    echo ""
    echo "Next step: Add currencies.json to JustSpentTests target in Xcode"
    exit 1
elif grep -q "EXC_BREAKPOINT\|SIGTRAP" test-output.log; then
    echo "❌ TEST CRASHED - Fix didn't work"
    exit 2
else
    echo "⚠️  Unexpected result - check test-output.log"
    exit 1
fi
