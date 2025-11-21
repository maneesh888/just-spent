# Just Spent - Android Voice Commands Guide

## Overview

This guide explains the recommended voice command patterns for Just Spent on Android with Google Assistant.

## Recommended Voice Command Patterns

### ✅ Grammatically Correct Patterns

**Pattern 1: "log ... in Just Spent"**
```
"Hey Google, log 50 dirhams for groceries in Just Spent"
"Hey Google, log 100 dollars for shopping in Just Spent"
```

**Pattern 2: "record ... in Just Spent"**
```
"Hey Google, record 75 dirhams for food in Just Spent"
"Hey Google, record expense in Just Spent"
```

**Pattern 3: "track ... using Just Spent"**
```
"Hey Google, track 200 dirhams using Just Spent"
"Hey Google, track expense using Just Spent"
```

**Pattern 4: "add ... to Just Spent"**
```
"Hey Google, add 50 dirhams for groceries to Just Spent"
"Hey Google, add expense to Just Spent"
```

### ❌ Avoid These Patterns (Grammatically Incorrect)

**Bad:** ~~"I spent 100 dollars in Just Spent"~~
- **Why wrong:** You spend money at a store, not IN an app

**Bad:** ~~"I just spent 50 dirhams on groceries"~~ (without app name)
- **Why wrong:** Google can't detect app invocation without explicit app name

**Bad:** ~~"Hey Google, Just Spent log 100 dirhams"~~
- **Why wrong:** App name should come at the end for natural speech flow

## Voice Command Structure

### Full Command Breakdown

```
"Hey Google, log 50 dirhams for groceries in Just Spent"
     │        │   │      │        │    │         │
     │        │   │      │        │    │         └─ App Name (required)
     │        │   │      │        │    └─ Preposition ("in", "using", "to")
     │        │   │      │        └─ Category (optional but recommended)
     │        │   │      └─ Currency (detected from context)
     │        │   └─ Amount (required)
     │        └─ Action Verb ("log", "record", "track", "add")
     └─ Wake Word
```

### Supported Action Verbs

- **log** - Most natural for expense tracking
- **record** - Professional and clear
- **track** - Alternative action verb
- **add** - Simple and direct

### Supported Prepositions

- **in** - "log 50 dirhams in Just Spent"
- **using** - "track expense using Just Spent"
- **to** - "add 100 dollars to Just Spent"
- **with** - "record expense with Just Spent"

## Categories

### Supported Categories

Google Assistant recognizes these categories (and synonyms):

1. **Food & Dining**
   - Synonyms: dining, restaurant, meal, food

2. **Grocery**
   - Synonyms: groceries, supermarket, shopping

3. **Transportation**
   - Synonyms: transportation, taxi, gas, fuel, transport

4. **Shopping**
   - Synonyms: store, mall, purchase, shopping

5. **Entertainment**
   - Synonyms: movie, cinema, fun, entertainment

6. **Bills & Utilities**
   - Synonyms: utility, electricity, rent, bills

7. **Healthcare**
   - Synonyms: doctor, hospital, medicine, healthcare

8. **Education**
   - Synonyms: school, course, training, education

9. **Other**
   - Synonyms: misc, miscellaneous, other

### Category Usage Examples

```
"Hey Google, log 50 dirhams for groceries in Just Spent"
"Hey Google, record 100 dollars for food in Just Spent"
"Hey Google, track 30 dirhams for taxi using Just Spent"
"Hey Google, add 200 dirhams for shopping to Just Spent"
```

## Currency Support

Just Spent automatically detects currency from:

1. **Explicit currency names:**
   - "dirhams" → AED
   - "dollars" → USD
   - "euros" → EUR
   - "pounds" → GBP
   - "rupees" → INR
   - "riyals" → SAR

2. **Currency symbols (in text/app context):**
   - $ → USD
   - € → EUR
   - £ → GBP
   - د.إ → AED

3. **Default currency:** Uses your device locale setting if not specified

## Two Ways to Use Voice Commands

### Method 1: Google Assistant (Hands-Free)

**Pros:**
- ✅ Completely hands-free
- ✅ Works when app is closed
- ✅ Great for driving or cooking

**Cons:**
- ⚠️ Requires "in Just Spent" phrase
- ⚠️ Needs 24-48 hours after Play Store deployment for Google indexing

**Example:**
```
"Hey Google, log 50 dirhams for groceries in Just Spent"
```

### Method 2: In-App Voice Button (Natural Speech)

**Pros:**
- ✅ No need to say app name
- ✅ More natural speech patterns
- ✅ Works immediately (no waiting for indexing)
- ✅ Faster response

**Cons:**
- ⚠️ Requires opening the app first

**Example:**
```
1. Open Just Spent app
2. Tap blue microphone FAB button
3. Say: "I spent 50 dirhams on groceries"
```

## Testing Voice Commands Locally

### Before Play Store Deployment

You can test the exact behavior Google Assistant will trigger using these scripts:

```bash
# Test voice command simulation
./test-google-assistant-final.sh

# Test in-app voice button
./test-voice-local.sh
```

These simulate the deep links Google Assistant will create when users say voice commands.

### After Play Store Deployment

1. **Deploy to Play Store Beta** (automatic via GitHub Actions)
2. **Wait 24-48 hours** for Google to index your app
3. **Test real voice commands** on your device:
   ```
   "Hey Google, log 100 dirhams for groceries in Just Spent"
   ```

## Troubleshooting

### "I couldn't find that app"

**Problem:** Google hasn't indexed your app yet
**Solution:** Wait 24-48 hours after Play Store deployment

### "Sorry, Just Spent can't do that"

**Problem:** Google doesn't recognize the action
**Solution:** Check that your voice command matches the recommended patterns above

### Categories Not Recognized

**Problem:** Google doesn't understand the category
**Solution:** Use exact category names or synonyms listed above

### App Opens but Expense Not Created

**Problem:** Category mapping or parameter extraction failed
**Solution:** Check logs:
```bash
adb logcat | grep -E "(VoiceCommand|ExpenseCreate|VoiceDeepLink)"
```

## Implementation Details

### How Google Assistant Works

1. **User speaks:** "Hey Google, log 50 dirhams for groceries in Just Spent"
2. **Google recognizes:** Money transfer intent with parameters
3. **Google finds app:** Searches Play Store index for "Just Spent"
4. **Google creates deep link:** `https://justspent.app/expense?command=log+50+dirhams+for+groceries`
5. **App receives intent:** VoiceDeepLinkActivity processes the command
6. **Expense created:** Parsed and saved to database

### Configuration Files

- **actions.xml:** Declares which Google Assistant intents we support
- **AndroidManifest.xml:** Declares intent filters for deep links
- **VoiceDeepLinkActivity.kt:** Processes incoming voice commands
- **VoiceCommandProcessor.kt:** Parses natural language and extracts entities

## Best Practices

### For Users

1. ✅ **Always include app name** ("in Just Spent", "using Just Spent")
2. ✅ **Use clear category names** (groceries, food, shopping)
3. ✅ **Speak at normal pace** (not too fast or slow)
4. ✅ **Use in-app button** for most natural experience

### For Developers

1. ✅ **Keep actions.xml updated** with all supported patterns
2. ✅ **Test locally first** before deploying to Play Store
3. ✅ **Monitor logs** for voice command failures
4. ✅ **Update documentation** when adding new categories

## Summary

**Recommended Pattern:**
```
"Hey Google, log [amount] [currency] for [category] in Just Spent"
```

**Example:**
```
"Hey Google, log 50 dirhams for groceries in Just Spent"
```

**Key Points:**
- ✅ Always include "in Just Spent", "using Just Spent", or "to Just Spent"
- ✅ Use action verbs: log, record, track, add
- ✅ Specify amount and category for best results
- ❌ Avoid "spent in Just Spent" (grammatically wrong)
- ❌ Don't omit app name (Google can't detect it)

---

**Last Updated:** November 2025
**Related Files:** `actions.xml`, `VoiceDeepLinkActivity.kt`, `VoiceCommandProcessor.kt`
