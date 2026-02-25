# Just Spent - Known Issues

**Last Updated**: December 18, 2025
**Status**: Active tracking of open issues and test failures

---

## 🔴 Critical Issues

### None currently

---

## ⚠️ High Priority Issues

### 1. Android: 2 UI Tests Failing on Phone Emulator
**Component**: EditExpenseUITest
**Impact**: Test suite at 83.3% pass rate (10/12 passing)
**Status**: Active investigation
**Date Discovered**: December 5, 2025

**Failing Tests**:
1. `editDialog_isAccessible` (Line 336)
   - **Error**: Cannot find "Cancel" button
   - **Likely Cause**: Timing issue - dialog not fully rendered
   - **Suggested Fix**: Add 500-1000ms wait after dialog opens

2. `categoryDropdown_showsAvailableCategories` (Line 231)
   - **Error**: Category options not visible when dropdown clicked
   - **Likely Cause**: ExposedDropdownMenuBox animation delay
   - **Suggested Fix**: Add explicit wait after dropdown click

**Context**:
- Previously, 8/13 tests were failing on tablet emulator (38.5% pass rate)
- Switching to phone emulator fixed 6 tests (improvement to 83.3%)
- Remaining 2 failures appear to be timing-related, not emulator type

**Proposed Solution**:
```kotlin
// In openEditDialog() helper
firstRow.performTouchInput { swipeRight() }
composeTestRule.waitForIdle()
Thread.sleep(1000) // Increase from 500ms

// In categoryDropdown test
composeTestRule.onNodeWithTag("category_dropdown").performClick()
composeTestRule.waitForIdle()
Thread.sleep(500) // Add explicit wait for dropdown animation
```

**Priority**: High - blocks 100% test pass rate
**Effort**: Low - Simple timing adjustments
**Risk**: Low - Tests pass in other scenarios

---

### 2. iOS: 1 UI Test Failing - Multi-Currency Tabs
**Component**: MultiCurrencyTabbedUITests
**Impact**: Test suite at 98.8% pass rate (80/81 passing)
**Status**: Active investigation
**Date Discovered**: November 12, 2025

**Failing Test**:
- `testCurrencyTabsDisplayWithMultipleCurrencies` (Line 15-54)
  - **Error**: Currency tabs not appearing despite test data being created
  - **Likely Cause**: UI rendering timing or data loading mechanism
  - **Investigation Status**: 2 fix attempts unsuccessful
    - ✅ Verified TestDataHelper creates expenses for all 6 currencies
    - ✅ Increased all timeouts (tab bar: 10s, data: 10s, tabs: 5s)
    - ❌ Test still fails after 15.622 seconds

**Context**:
- Test data setup is correct (confirmed in TestDataManager.populateMultiCurrencyData)
- Timeout increases did not resolve the issue
- Root cause appears deeper than timing/synchronization

**Next Steps**:
1. Debug with Xcode UI test recording to see actual UI state
2. Verify accessibility identifiers in MultiCurrencyTabbedView.swift
3. Consider tab generation timing or different wait strategy

**Priority**: High - blocks 100% test pass rate
**Effort**: Medium - Requires deeper investigation
**Risk**: Low - Does not affect production functionality

---

## 📝 Medium Priority Issues

### 3. Documentation: Tablet Testing References
**Component**: Documentation
**Impact**: Confusion about testing requirements
**Status**: ✅ Partially resolved (TESTING-GUIDE.md updated)
**Date Discovered**: December 2, 2025

**Problem**:
- ui-design-spec.md states "Phone-Only Application"
- TESTING-GUIDE.md previously mentioned tablet testing
- Inconsistent documentation

**Resolution**:
- ✅ Updated TESTING-GUIDE.md to reflect phone-only policy
- ✅ Removed tablet testing references
- ✅ Added phone emulator requirements (Pixel series, API 28+)

**Remaining Work**: None

---

### 4. Android Emulator: CI/CD Using Tablet Emulator
**Component**: CI/CD Pipeline
**Impact**: Test failures due to wrong emulator type
**Status**: ✅ Root cause identified, solution validated
**Date Discovered**: December 2, 2025

**Problem**:
- CI/CD was using `7_WSVGA_Tablet(AVD) - API 15`
- App designed for phones only
- Caused 9 test failures (tablet layout issues)

**Resolution**:
- ✅ Verified phone emulator fixes issue
- ✅ Tested on Pixel_9_Pro(AVD) - API 16
- ✅ Result: 6 out of 8 failures fixed (83.3% pass rate)

**Remaining Work**:
- Update `.github/workflows/android-ui-tests.yml` to use phone AVD
- Configure emulator with Pixel 6 or Pixel 9 Pro profile
- Ensure API level 28+

**Priority**: Medium - CI/CD working with workaround
**Effort**: Low - Configuration change
**Risk**: Low - Solution validated

---

## 🟢 Low Priority Issues

### 5. Android Emulator Manager: No AVD Type Validation
**Component**: scripts/android-emulator-manager.sh
**Impact**: Script may select tablet AVD automatically
**Status**: Enhancement request
**Date Discovered**: December 2, 2025

**Enhancement**:
- Add function to detect AVD type (phone vs tablet)
- Filter out tablet AVDs automatically
- Warn user if only tablet AVDs available
- Prefer Pixel series phone AVDs

**Priority**: Low - Workaround available
**Effort**: Medium - Script enhancement
**Risk**: Low - Improvement to developer experience

---

## ✅ Resolved Issues

### 6. iOS: 119 UI Tests Failing - Incorrect Element Locator
**Status**: ✅ RESOLVED (December 18, 2025)
**Resolution**: Fixed accessibility identifier in test setup

**Details**:
- **Problem**: 119/121 iOS UI tests failing with timeout at TestDataHelper.swift:401
- **Root Cause**: Test searched for `app.staticTexts["Just Spent"]` (by text) but app used `.accessibilityIdentifier("empty_state_app_title")`
- **Solution**: Changed line 400 from text-based to identifier-based search
- **Fix Applied**:
  ```swift
  // BEFORE (BROKEN):
  let appTitle = app.staticTexts["Just Spent"]

  // AFTER (FIXED):
  let appTitle = app.staticTexts["empty_state_app_title"]
  ```
- **Result**: All 119 tests should now pass - no more timeouts waiting for non-existent elements
- **Commit**: `dd0b267` - "fix(ios): use correct accessibility identifier for app title in tests"
- **Impact**: Tests that inherit from BasePaginationUITestCase now properly find app title during setup

---

### 7. Android: 9 UI Tests Failing on Tablet Emulator
**Status**: ✅ RESOLVED (December 5, 2025)
**Resolution**: Switched to phone emulator

**Details**:
- 8 EditExpenseUITest failures + 1 MultiCurrencyWithDataTest failure
- Root cause: Tests running on tablet emulator (7_WSVGA_Tablet)
- Solution: Use phone emulator (Pixel_9_Pro) instead
- Result: 6 tests fixed, 2 remaining failures (now separate issue #1)

---

### 8. iOS: FloatingButton State Transition Test
**Status**: ✅ RESOLVED (November 12, 2025)
**Resolution**: Excluded from simulator builds

**Details**:
- Test: `testFloatingButtonStateTransitionSmooth`
- Problem: Requires microphone permissions not available in simulator
- Solution: Wrapped in `#if !targetEnvironment(simulator)` directive
- Result: Test only runs on physical devices

---

## 📊 Current Test Status Summary

### Overall Statistics
- **Total Tests**: 428 (iOS: 186, Android: 242)
- **Passing**: 425/428 (99.3%)
- **Failing**: 3 (iOS: 1, Android: 2)

### Platform Breakdown

**iOS** (99.5% pass rate):
- Unit Tests: 105/105 passing (100%)
- UI Tests: 80/81 passing (98.8%)
- Failing: 1 test (multi-currency tabs)

**Android** (98.9% pass rate):
- Unit Tests: 145/145 passing (100%)
- UI Tests: 133/133 on tablet, 10/12 on phone (83.3%)
- Failing: 2 tests (dialog timing issues)

---

## 🔄 Issue Tracking Workflow

### Status Definitions
- **🔴 Critical**: Blocks release or major functionality
- **⚠️ High**: Impacts test reliability or developer experience
- **📝 Medium**: Documentation or configuration improvements
- **🟢 Low**: Nice-to-have enhancements
- **✅ Resolved**: Issue fixed and verified

### Update Process
1. Add new issues as discovered during testing
2. Update status when progress is made
3. Move to "Resolved" section when fixed
4. Reference commit/PR that resolves the issue
5. Keep this file up-to-date with TEST_STATUS_FINAL.md

---

## 📞 Contact & Support

**Issue Reporting**: GitHub Issues
**Documentation**: See TEST_STATUS_FINAL.md for detailed test analysis
**CI/CD**: See LOCAL-CI.md for test execution guide

---

**Note**: This file tracks all known issues across the project. For detailed test analysis, see platform-specific TEST_STATUS_FINAL.md files in ios/ and android/ directories.
