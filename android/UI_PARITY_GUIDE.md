# Android vs iOS UI Parity Guide

## Current State Analysis (Based on Screenshot)

### What You're Seeing:
✅ **SingleCurrencyScreen** - Correct! (Only AED expenses exist)
✅ **TopAppBar** - "Just Spent" title visible
⚠️ **Currency Display** - Shows "د.إ.200" (Arabic numerals for AED)
⚠️ **No Tabs** - Expected behavior when only one currency exists

## Multi-Currency UI Trigger

### How to See Currency Tabs:

You need expenses in **2 or more different currencies**. Currently you have:
- ✅ AED 20.00 expense (shown in screenshot)

To see the tabbed interface, add an expense in another currency via voice:
- "I spent 50 dollars on groceries" → Creates USD expense
- "I spent 30 euros on shopping" → Creates EUR expense

### Conditional UI Logic:

```kotlin
when {
    expenses.isEmpty() ->
        ExpenseListWithVoiceScreen (empty state)

    activeCurrencies.size > 1 ->
        MultiCurrencyTabbedScreen (TABS APPEAR HERE)

    else ->
        SingleCurrencyScreen (CURRENT STATE - no tabs)
}
```

## Expected Behavior:

### Scenario 1: Single Currency (Current)
```
┌─────────────────────────┐
│  Just Spent             │ ← TopAppBar
├─────────────────────────┤
│  Total                  │
│  AED 200.00             │ ← Single currency total
├─────────────────────────┤
│  Other - AED 20.00      │ ← Expense list
│  10/22/2025             │
└─────────────────────────┘
```

### Scenario 2: Multiple Currencies (After adding USD/EUR)
```
┌─────────────────────────┐
│  Just Spent             │ ← TopAppBar
├─────────────────────────┤
│ [AED] [USD] [EUR]       │ ← CURRENCY TABS (Scrollable)
├─────────────────────────┤
│  Total                  │
│  AED 200.00             │ ← Selected currency total
├─────────────────────────┤
│  Other - AED 20.00      │ ← Filtered by selected currency
│  10/22/2025             │
└─────────────────────────┘
```

## Testing Instructions

### Step 1: Verify Current State
- ✅ You're seeing SingleCurrencyScreen (correct for one currency)
- ✅ TopAppBar shows "Just Spent"
- ✅ Can see total and expense list

### Step 2: Add Second Currency
Open the app and use voice:
1. Tap the microphone button
2. Say: **"I spent 50 dollars on food"**
3. Confirm the expense

### Step 3: Observe UI Change
After adding USD expense, the UI should **automatically switch** to show:
- ✅ Currency tabs at top: `[AED] [USD]`
- ✅ Tappable tabs to switch between currencies
- ✅ Filtered expense list per currency
- ✅ Per-currency totals

### Step 4: Test Tab Switching
1. Tap the **USD** tab
2. See only USD expenses (the $50 food item)
3. See USD total
4. Tap the **AED** tab
5. See only AED expenses (the د.إ.20 item)
6. See AED total

## Currency Formatting

### Current Behavior:
The app uses **locale-aware** formatting:
- AED: Shows "د.إ.200" (Arabic symbol) for UAE locale
- USD: Shows "$50.00" for US locale
- EUR: Shows "€30.00" for EU locale

### To Force English Formatting:
If you prefer "AED 200.00" instead of "د.إ.200", we can modify the CurrencyFormatter to use English formatting regardless of device locale.

## Visual Design Notes

### Current Android Design:
- Material 3 design system
- System dark/light theme support
- Elevation and shadows for cards
- Primary blue color for selection

### iOS Design:
- SwiftUI native components
- System dark/light theme support
- Similar elevation and visual hierarchy
- Blue accent color

Both platforms should look similar but with platform-specific visual language.

## Troubleshooting

### "I don't see tabs even with multiple currencies"
- Check that expenses have different currency codes in database
- Verify `activeCurrencies.size > 1` condition
- Check logs for currency detection

### "Tabs don't switch when tapped"
- Should work - `onClick = { onCurrencySelected(currency) }` is implemented
- Try tapping different areas of the tab
- Check if touch is being intercepted

### "Total shows wrong format"
- This is locale-aware formatting (correct behavior)
- Can be changed to always use English if preferred

## Next Steps

1. **Test multi-currency**: Add USD or EUR expense via voice
2. **Verify tabs appear**: Should see tab bar with multiple currencies
3. **Test tab switching**: Click different tabs to filter expenses
4. **Report issues**: If tabs don't work, let me know the specific behavior

---

**Note**: The screenshot shows the **correct behavior** for a single currency.
Tabs only appear when you have expenses in 2+ different currencies.
