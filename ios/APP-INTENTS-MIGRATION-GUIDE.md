# App Intents Migration Guide - How Siri Parameter Capture Works

## Overview

This document explains how the modern App Intents framework handles voice commands and parameter collection.

---

## How It Works: Two Approaches

### Approach 1: Simple Phrase + Follow-up Questions (Recommended for New Users)

**User says:** "Hey Siri, log expense in Just Spent"

**What happens:**
1. Siri recognizes the shortcut phrase
2. Siri sees that `amount` parameter is required but missing
3. Siri asks: **"How much did you spend?"**
4. User responds: "50 dirhams"
5. Siri sees `category` is optional but helpful
6. Siri asks: **"What category is this expense for?"**
7. User responds: "Food"
8. Siri asks: **"Where did you make this purchase?"**
9. User responds: "Starbucks" (or "skip")
10. Intent executes and saves expense
11. Siri confirms: **"Logged د.إ 50.00 at Starbucks for Food & Dining"**

**Code Implementation:**
```swift
@Parameter(
    title: "Amount",
    description: "The expense amount",
    requestValueDialog: IntentDialog("How much did you spend?")
)
var amount: Double
```

The `requestValueDialog` tells Siri what question to ask when the parameter is missing.

---

### Approach 2: All-in-One Natural Language (Advanced)

**User says:** "Hey Siri, I just spent 50 dirhams on food at Starbucks using Just Spent"

**What happens:**
1. Siri recognizes "Just Spent" app name
2. App Intents framework uses natural language processing to extract:
   - **Amount**: 50
   - **Currency**: dirhams → AED
   - **Category**: food → "Food & Dining"
   - **Merchant**: Starbucks
3. Intent executes immediately with all parameters
4. Siri confirms: **"Logged د.إ 50.00 at Starbucks for Food & Dining"**

**How it extracts parameters:**
- Numbers are detected as amounts
- Currency keywords ("dirhams", "dollars", etc.) map to currency codes
- Category keywords ("food", "groceries", etc.) map to predefined categories
- Remaining text is treated as merchant name

---

## Parameter Types

### Required Parameters
```swift
@Parameter(title: "Amount", description: "The expense amount")
var amount: Double  // NOT optional - Siri MUST ask if missing
```

If user doesn't provide in voice command, Siri will ask follow-up question.

### Optional Parameters
```swift
@Parameter(title: "Merchant", description: "Merchant or vendor name")
var merchant: String?  // Optional - Siri MAY ask or skip
```

Siri may ask for optional parameters if they're in the `parameterSummary`, but user can skip.

### Default Parameters
```swift
@Parameter(title: "Currency", description: "Currency code", default: "AED")
var currency: String  // Uses "AED" if not specified
```

If user doesn't specify, the default value is used without asking.

---

## Category Keyword Mapping

The intent has intelligent category mapping:

```swift
"food" / "dining" / "restaurant" / "lunch" → "Food & Dining"
"grocery" / "groceries" / "supermarket" → "Grocery"
"transport" / "taxi" / "uber" / "gas" → "Transportation"
"shopping" / "clothes" / "mall" → "Shopping"
"movie" / "cinema" / "concert" → "Entertainment"
"bills" / "utilities" / "electricity" → "Bills & Utilities"
"doctor" / "hospital" / "medicine" → "Healthcare"
"school" / "course" / "training" → "Education"
```

**Example:**
- User says: "groceries" → Intent saves as "Grocery"
- User says: "taxi" → Intent saves as "Transportation"

---

## Currency Detection

```swift
Currency symbols and keywords:
"AED" / "dirhams" → د.إ (UAE Dirham)
"USD" / "dollars" → $ (US Dollar)
"EUR" / "euros" → € (Euro)
"GBP" / "pounds" → £ (British Pound)
"INR" / "rupees" → ₹ (Indian Rupee)
"SAR" / "riyals" → ﷼ (Saudi Riyal)
```

Default: AED (set in parameter default)

---

## Example Voice Commands

### Simple Commands (Siri asks questions):
1. "Hey Siri, log expense in Just Spent"
2. "Hey Siri, add expense in Just Spent"
3. "Hey Siri, track expense in Just Spent"

### Natural Language Commands (All-in-one):
1. "Hey Siri, I just spent 100 dirhams on groceries using Just Spent"
2. "Hey Siri, I spent 50 dollars at Starbucks for food using Just Spent"
3. "Hey Siri, log 200 dirhams for transportation in Just Spent"
4. "Hey Siri, I paid 25 euros for entertainment using Just Spent"

### View Commands:
1. "Hey Siri, show my expenses in Just Spent"
2. "Hey Siri, view my spending in Just Spent"
3. "Hey Siri, check my expenses in Just Spent"

---

## Why This Approach Works Better Than Old SiriKit

### Old SiriKit (.intentdefinition):
- Required manual entity extraction
- Limited natural language understanding
- Complex configuration
- Harder to maintain

### Modern App Intents:
- ✅ Built-in parameter prompting (Siri asks questions automatically)
- ✅ Natural language parsing (extracts parameters from speech)
- ✅ Type-safe Swift code (compiler checks)
- ✅ Easier to maintain (pure Swift, no XML)
- ✅ Better Siri integration (follows system patterns)

---

## Testing on Device

### Quick Test Checklist:
1. ✅ Deploy to physical device (Siri doesn't work in simulator)
2. ✅ Check console for "🎤 App Shortcuts registered for Siri"
3. ✅ Wait 5-10 minutes for Siri indexing
4. ✅ Try simple command: "Hey Siri, log expense in Just Spent"
5. ✅ Answer Siri's follow-up questions
6. ✅ Verify expense appears in app
7. ✅ Try natural language: "Hey Siri, I just spent 50 dirhams on food using Just Spent"

### Troubleshooting:
- **Siri says "I can't help with that"**: Wait longer (up to 10 minutes for indexing)
- **Siri doesn't recognize app name**: Check Shortcuts app → should see "Log Expense" shortcut
- **Parameters not being asked**: Check parameter definitions have `requestValueDialog`
- **Amount not saving**: Check that `amount` is marked as required (not optional)

---

## Advanced: Custom Parameter Values

You can also provide parameter values in the Shortcuts app:

1. Open Shortcuts app
2. Find "Log Expense" shortcut
3. Tap to edit
4. Set default values for amount, category, merchant
5. Save custom shortcut with phrase like "My morning coffee"
6. Say: "Hey Siri, my morning coffee" → Logs $5 for Food automatically

This is useful for recurring expenses (daily coffee, weekly groceries, etc.)

---

**Last Updated**: November 17, 2025
**Framework**: App Intents (iOS 16+)
**Status**: ✅ Production Ready
