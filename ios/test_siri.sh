#!/bin/bash

echo "🎙️  Siri Integration Test Script"
echo "================================"

# Check if we're in the right directory
if [ ! -f "JustSpent.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the ios/JustSpent directory"
    exit 1
fi

echo "📱 Building and running Just Spent..."

# Build the project
xcodebuild -project JustSpent.xcodeproj -scheme JustSpent -destination 'platform=iOS Simulator,name=iPhone 15' build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    echo ""
    echo "🧪 Test Instructions:"
    echo "===================="
    echo ""
    echo "1. Run the app on your device (not simulator for Siri)"
    echo "2. Open the app and tap 'Test Siri Integration'"
    echo "3. Create shortcuts by tapping the buttons"
    echo "4. Wait 5-10 seconds for iOS to register shortcuts"
    echo "5. Try these voice commands:"
    echo ""
    echo "   📝 \"Hey Siri, Log 25 dollars for food\""
    echo "   📝 \"Hey Siri, Log 50 dollars for grocery\""
    echo "   📝 \"Hey Siri, Show my expenses\""
    echo ""
    echo "6. If Siri doesn't recognize, check:"
    echo "   - Settings → Siri & Search → Just Spent"
    echo "   - Settings → Siri & Search → Shortcuts"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "==================="
    echo ""
    echo "If voice commands don't work:"
    echo "• Use the app a few times manually first"
    echo "• Wait 24-48 hours for Siri to learn patterns"
    echo "• Check that Siri is enabled in Settings"
    echo "• Try creating shortcuts in the Shortcuts app manually"
    echo ""
    echo "Alternative test:"
    echo "• Open Shortcuts app → Create new shortcut"
    echo "• Add 'Open App' action → select Just Spent"
    echo "• Record phrase: 'Open expense tracker'"
    echo ""
    
else
    echo "❌ Build failed. Check the errors above."
    exit 1
fi