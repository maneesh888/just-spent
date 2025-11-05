# Android UI Test Fixes - Remaining Work

## Status
- ✅ **Unit Tests**: 145/145 passing (100%)
- ⚠️ **UI Tests**: 83/88 passing (94.3%)
- ❌ **5 UI tests still failing**

## Root Cause Identified

**Critical Finding**: All failing tests have **excessive `Thread.sleep()` calls** that break Compose test synchronization.

### Pattern Discovered
- ✅ Tests with **only** `waitForIdle()` → **PASS**
- ❌ Tests with **extra** `Thread.sleep()` → **FAIL**

## 5 Failing Tests & Fixes

### 1. `onboarding_displaysAEDOption`
**File**: `OnboardingFlowUITest.kt:81-89`

**Current Code**:
```kotlin
@Test
fun onboarding_displaysAEDOption() {
    composeTestRule.waitForIdle()
    Thread.sleep(2000) // ← REMOVE THIS

    composeTestRule.onNodeWithTag("currency_option_AED")
        .assertExists()
        .assertHasClickAction()
}
```

**Fix**: Remove `Thread.sleep(2000)` - other currency tests pass without it

---

### 2. `onboarding_savesSelectedCurrency`
**File**: `OnboardingFlowUITest.kt:268-281`

**Current Code**:
```kotlin
@Test
fun onboarding_savesSelectedCurrency() {
    composeTestRule.waitForIdle()
    Thread.sleep(2000) // ← REMOVE THIS

    composeTestRule.onNodeWithTag("currency_option_USD")
        .performClick()

    composeTestRule.waitForIdle()
}
```

**Fix**: Remove `Thread.sleep(2000)`

---

### 3. `emptyState_titleIsAccessible`
**File**: `EmptyStateUITest.kt:260-270`

**Current Code**:
```kotlin
@Test
fun emptyState_titleIsAccessible() {
    composeTestRule.waitForIdle()
    Thread.sleep(2000) // ← REMOVE THIS

    composeTestRule.onNodeWithTag("empty_state_title", useUnmergedTree = true)
        .assertExists()
        .assertIsDisplayed()
}
```

**Fix**: Remove `Thread.sleep(2000)` - other empty state tests pass without it

---

### 4. `recordingIndicator_stateChanges`
**File**: `FloatingActionButtonUITest.kt:280-298`

**Current Code**:
```kotlin
@Test
fun recordingIndicator_stateChanges() {
    val fab = composeTestRule.onNodeWithTag("voice_fab")
    fab.assertExists()
    fab.performClick()
    composeTestRule.waitForIdle()
    Thread.sleep(1000) // ← REDUCE TO 500ms or remove

    val listeningText = composeTestRule.onNodeWithText("Listening...", useUnmergedTree = true)
    listeningText.assertExists()
    listeningText.assertIsDisplayed()
}
```

**Fix**: Reduce to `Thread.sleep(500)` or remove entirely

---

### 5. `switchingTabs_showsCorrectDataPerCurrency`
**File**: `MultiCurrencyWithDataTest.kt:385-392` (helper function)

**Current Code**:
```kotlin
private fun clickTab(currency: String) {
    val tab = composeTestRule.onAllNodesWithText(currency, substring = true, useUnmergedTree = true)
        .onFirst()
    tab.performClick()
    composeTestRule.waitForIdle()
    Thread.sleep(500)  // ← REMOVE THIS
    Thread.sleep(2500) // ← REMOVE THIS
}
```

**Fix**: Remove **both** `Thread.sleep()` calls - rely only on `waitForIdle()`

---

## Why These Fixes Will Work

1. **Compose Test Rule** already provides proper synchronization via `waitForIdle()`
2. **Extra sleeps** cause problems:
   - Allow unwanted recomposition during wait
   - Break test/UI state synchronization
   - May trigger activity lifecycle changes
   - LazyColumn can render/unrender items during sleep

3. **Evidence**: 83 tests pass using only `waitForIdle()`, including:
   - ✅ `onboarding_displaysUSDOption` (no sleep)
   - ✅ `onboarding_displaysEUROption` (no sleep)
   - ✅ `onboarding_displaysGBPOption` (no sleep)
   - ✅ `onboarding_displaysINROption` (no sleep)
   - ✅ `onboarding_displaysSAROption` (no sleep)
   - ❌ `onboarding_displaysAEDOption` (has 2000ms sleep) ← **ONLY ONE THAT FAILS**

---

## Changes Already Applied

### ✅ Completed Fixes
1. SAR currency symbol: "﷼" → "ر.س" (3 files)
2. Added `useUnmergedTree = true` where needed
3. Added `scenario.recreate()` for onboarding
4. LazyColumn height: `.height(400.dp)`
5. All 145 unit tests passing

### Modified Files
- `Currency.kt` - SAR symbol updated
- `CurrencyFormatter.kt` - SAR symbol in parse list
- `CurrencyTest.kt` - SAR assertion updated
- `CurrencyFormatterTest.kt` - SAR format test updated
- `CurrencyOnboardingScreen.kt` - Fixed LazyColumn height
- `OnboardingFlowUITest.kt` - Added scenario.recreate()
- `EmptyStateUITest.kt` - Added useUnmergedTree
- `FloatingActionButtonUITest.kt` - Added useUnmergedTree
- `MultiCurrencyWithDataTest.kt` - Added tab click delay

---

## Next Session Action Plan

1. **Remove sleep calls** from 5 failing tests (5-minute task)
2. **Run UI tests** to verify all 88 tests pass
3. **Run full CI/CD** to confirm 100% pass rate
4. **Commit final fixes** with comprehensive test results

---

## Expected Final Result

- ✅ Unit Tests: 145/145 (100%)
- ✅ UI Tests: 88/88 (100%)
- ⚡ Faster test execution (~10 seconds saved)
- 🎯 More reliable tests (proper Compose sync)

---

**Date**: January 29, 2025
**Branch**: `fix/ios-ui-tests` (Android fixes included)
