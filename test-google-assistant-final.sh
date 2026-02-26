#!/bin/bash

DEVICE_ID="0f281937"

echo "🤖 Google Assistant App Actions - Local Simulation"
echo "==================================================="
echo ""
echo "This simulates what Google Assistant will do when you say:"
echo "\"Hey Google, log 50 dirhams for groceries in Just Spent\""
echo ""
echo "Recommended voice patterns:"
echo "  • \"log [amount] for [category] in Just Spent\""
echo "  • \"record [amount] for [category] in Just Spent\""
echo "  • \"track [amount] using Just Spent\""
echo ""
echo "NOTE: Using natural language command format for proper category mapping"
echo ""

# Delete previous test expenses first
echo "🗑️  Clearing previous test expenses..."
adb -s $DEVICE_ID shell am broadcast -a com.justspent.expense.CLEAR_TEST_DATA
sleep 1

# Test 1: Grocery expense - using correct category format
echo "📱 TEST 1: Grocery Expense (AED 50 at Carrefour)"
echo "------------------------------------------------"
adb -s $DEVICE_ID shell am start \
  -n com.justspent.expense/.ui.voice.VoiceDeepLinkActivity \
  -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?command=I%20spent%2050%20dirhams%20on%20groceries%20at%20Carrefour"

echo ""
echo "✅ Grocery expense sent!"
echo ""
sleep 3

# Test 2: Food expense - using command format
echo "📱 TEST 2: Food Expense (USD 100 at Starbucks)"
echo "----------------------------------------------"
adb -s $DEVICE_ID shell am start \
  -n com.justspent.expense/.ui.voice.VoiceDeepLinkActivity \
  -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?command=I%20spent%20100%20dollars%20on%20food%20at%20Starbucks"

sleep 2
echo "✅ Food expense sent!"
echo ""

# Test 3: Shopping expense - using command format
echo "📱 TEST 3: Shopping Expense (AED 200)"
echo "-------------------------------------"
adb -s $DEVICE_ID shell am start \
  -n com.justspent.expense/.ui.voice.VoiceDeepLinkActivity \
  -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?command=I%20spent%20200%20dirhams%20on%20shopping"

sleep 2
echo "✅ Shopping expense sent!"
echo ""

# Test 4: Transportation expense
echo "📱 TEST 4: Transportation Expense (AED 30 for taxi)"
echo "--------------------------------------------------"
adb -s $DEVICE_ID shell am start \
  -n com.justspent.expense/.ui.voice.VoiceDeepLinkActivity \
  -a android.intent.action.VIEW \
  -d "https://justspent.app/expense?command=I%20spent%2030%20dirhams%20on%20taxi"

sleep 2
echo "✅ Transportation expense sent!"
echo ""

echo "🎉 All Google Assistant simulations completed!"
echo ""
echo "📋 Check your device - you should see 4 new expenses:"
echo "   1. AED 50 - Grocery (Carrefour)"
echo "   2. USD 100 - Food & Dining (Starbucks)"
echo "   3. AED 200 - Shopping"
echo "   4. AED 30 - Transportation"
echo ""
echo "💡 These expenses should now have the CORRECT categories!"
echo ""
echo "🔧 TECHNICAL NOTE:"
echo "   Using 'command' parameter instead of structured parameters."
echo "   This triggers the VoiceCommandProcessor which properly maps categories."
echo ""
