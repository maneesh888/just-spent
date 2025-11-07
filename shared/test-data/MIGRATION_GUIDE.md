# Test Data Consolidation - Migration Guide

## 📊 **Problem Statement**

### Current State (Before Consolidation)

**Massive Test Data Duplication:**
```
Android:
├── VoiceCurrencyDetectorTest.kt         1,219 lines  ❌ Duplicated
├── TestDataHelper.kt                      257 lines  ❌ Duplicated
└── CurrencyFormatterTest.kt               267 lines  ❌ Duplicated

iOS:
├── VoiceCurrencyDetectorTests.swift       283 lines  ❌ Duplicated
├── TestDataManager.swift                  193 lines  ❌ Duplicated
├── TestData.swift                         297 lines  ❌ Duplicated
└── TestDataHelper.swift                   342 lines  ❌ Duplicated

Total: ~2,858 lines of duplicated test data
```

**Issues:**
1. ❌ Test data hardcoded in every test file
2. ❌ Same test cases written twice (Android + iOS)
3. ❌ Adding new currency = update 6+ files
4. ❌ Inconsistencies between platforms
5. ❌ Maintenance nightmare

---

## ✅ **Solution: Shared JSON Test Data**

### New Architecture

```
shared/test-data/                          ✅ Single Source of Truth
├── voice-test-data.json            200+ test cases (all currencies)
├── test-expenses.json              Sample expenses for UI tests
├── currency-reference.json         36 currencies metadata
├── category-reference.json         9 categories with keywords
├── formatting-test-cases.json      19 formatting edge cases
├── validation-rules.json           Validation constraints
└── error-scenarios.json            40+ error cases

Android:
├── SharedTestDataLoader.kt          ~100 lines  ✅ Loader utility
└── VoiceCurrencyDetectorRefactoredTest.kt  ~200 lines  ✅ Data-driven tests

iOS:
├── SharedTestDataLoader.swift        ~100 lines  ✅ Loader utility
└── VoiceCurrencyDetectorRefactoredTests.swift  ~200 lines  ✅ Data-driven tests

Total: ~600 lines (vs 2,858 lines before)
Reduction: 79% less code!
```

---

## 🔄 **Migration Steps**

### Step 1: Add Test Data Loaders

#### Android

Create `SharedTestDataLoader.kt`:

```kotlin
// android/app/src/test/java/com/justspent/app/utils/SharedTestDataLoader.kt
object SharedTestDataLoader {
    fun loadVoiceTestData(): VoiceTestData {
        val jsonFile = File("../../shared/test-data/voice-test-data.json")
        return gson.fromJson(jsonFile.readText(), VoiceTestData::class.java)
    }

    fun getCurrencyDetectionTests(): List<VoiceTestCase> {
        return loadVoiceTestData().test_suites.currency_detection.tests
    }
}
```

#### iOS

Create `SharedTestDataLoader.swift`:

```swift
// ios/JustSpentTests/Utilities/SharedTestDataLoader.swift
class SharedTestDataLoader {
    static func loadVoiceTestData() throws -> VoiceTestData {
        let jsonPath = "../../shared/test-data/voice-test-data.json"
        let data = try Data(contentsOf: URL(fileURLWithPath: jsonPath))
        return try JSONDecoder().decode(VoiceTestData.self, from: data)
    }

    static func getCurrencyDetectionTests() throws -> [VoiceTestCase] {
        return try loadVoiceTestData().test_suites.currency_detection.tests
    }
}
```

### Step 2: Refactor Tests to Use Shared Data

#### Before (Hardcoded):

```kotlin
// ❌ OLD: 70+ individual test methods with hardcoded data
@Test
fun `detectCurrency finds AED from dirham keyword`() {
    val text = "I spent 100 dirhams on groceries"
    val result = VoiceCurrencyDetector.detectCurrency(text)
    assertThat(result).isEqualTo(Currency.AED)
}

@Test
fun `detectCurrency finds AED from dirhams plural`() {
    val text = "paid 50 dirhams for taxi"
    val result = VoiceCurrencyDetector.detectCurrency(text)
    assertThat(result).isEqualTo(Currency.AED)
}

// ... 68 more similar methods
```

#### After (Data-Driven):

```kotlin
// ✅ NEW: One test that runs all cases from JSON
@Test
fun `currency detection tests from shared JSON`() {
    val testCases = SharedTestDataLoader.getCurrencyDetectionTests()

    testCases.forEach { testCase ->
        val result = VoiceCurrencyDetector.detectCurrency(testCase.input)
        val expected = Currency.fromCode(testCase.expected_currency)
        assertThat(result).isEqualTo(expected)
        println("✓ ${testCase.id}: ${testCase.description}")
    }
}
```

**Result:**
- **Before**: 70 test methods, 1,219 lines
- **After**: 5 test methods, 200 lines
- **Reduction**: 84% less code!

### Step 3: Migrate Existing Tests

For each test file:

1. **Identify test patterns** (e.g., currency detection, amount extraction)
2. **Check if JSON already has those cases** (it probably does!)
3. **Replace hardcoded tests** with data-driven tests using loader
4. **Keep a few legacy tests** for regression (optional)
5. **Run tests to verify** everything still passes

---

## 📈 **Impact Analysis**

### Code Reduction

| File | Before | After | Reduction |
|------|--------|-------|-----------|
| **Android Voice Tests** | 1,219 lines | 200 lines | **84%** ↓ |
| **iOS Voice Tests** | 283 lines | 200 lines | **29%** ↓ |
| **Android Test Helper** | 257 lines | 50 lines* | **81%** ↓ |
| **iOS Test Manager** | 193 lines | 40 lines* | **79%** ↓ |
| **Total Platform Code** | 1,952 lines | 490 lines | **75%** ↓ |

*Loaders only, data moved to JSON

### Maintenance Reduction

| Task | Before | After |
|------|--------|-------|
| **Add new currency test** | Update 6+ files | Update 1 JSON file |
| **Fix test data bug** | Find/replace in all files | Fix once in JSON |
| **Add new test case** | Write code in 2 files | Add JSON entry |
| **Sync iOS/Android tests** | Manual comparison | Automatic (shared data) |

---

## 🎯 **Benefits**

### 1. **Single Source of Truth**
- ✅ Test data defined once, used everywhere
- ✅ No sync issues between iOS and Android
- ✅ Guaranteed consistency

### 2. **Easier Maintenance**
- ✅ Add new currency: Update JSON only
- ✅ Fix bug: Change JSON, not code
- ✅ Add test case: JSON entry (no code change)

### 3. **Better Coverage**
- ✅ All 36 currencies tested comprehensively
- ✅ Edge cases documented in one place
- ✅ Error scenarios shared across platforms

### 4. **Faster Development**
- ✅ Write tests faster (no copy/paste)
- ✅ Review tests easier (read JSON vs code)
- ✅ Onboard new developers faster (clear structure)

### 5. **Version Control Benefits**
- ✅ Cleaner diffs (JSON changes vs code changes)
- ✅ Easier to review (test data vs test logic)
- ✅ Better git history (separate concerns)

---

## 🚀 **Example: Adding a New Currency**

### Before (Update 6+ Files):

```kotlin
// File 1: Android VoiceCurrencyDetectorTest.kt
@Test
fun `detectCurrency finds HRK from kuna keyword`() {
    val text = "I spent 100 kuna"
    val result = VoiceCurrencyDetector.detectCurrency(text)
    assertThat(result).isEqualTo(Currency.HRK)
}

// File 2: iOS VoiceCurrencyDetectorTests.swift
func testDetectKunaKeyword() throws {
    let transcript = "I spent 100 kuna"
    let result = detector.detectCurrency(from: transcript)
    XCTAssertEqual(result, "HRK")
}

// File 3: Android CurrencyTest.kt
// ... add HRK tests

// File 4: iOS CurrencyTests.swift
// ... add HRK tests

// File 5: Android TestDataHelper.kt
// ... add HRK expense samples

// File 6: iOS TestDataManager.swift
// ... add HRK expense samples
```

### After (Update 1 JSON File):

```json
{
  "id": "hrk_kuna_keyword",
  "input": "I spent 100 kuna",
  "expected_currency": "HRK",
  "expected_amount": 100.0,
  "description": "Detect HRK from 'kuna' keyword"
}
```

**That's it!** Both Android and iOS tests automatically include it.

---

## 📝 **Migration Checklist**

### Phase 1: Setup (Do First)
- [x] Create `shared/test-data/` directory
- [x] Add JSON test data files
- [x] Create Android `SharedTestDataLoader.kt`
- [x] Create iOS `SharedTestDataLoader.swift`

### Phase 2: Refactor Tests (Your Current Step)
- [ ] Migrate `VoiceCurrencyDetectorTest.kt` → use SharedTestDataLoader
- [ ] Migrate `VoiceCurrencyDetectorTests.swift` → use SharedTestDataLoader
- [ ] Migrate `TestDataHelper.kt` → load from `test-expenses.json`
- [ ] Migrate `TestDataManager.swift` → load from `test-expenses.json`
- [ ] Migrate `CurrencyFormatterTest.kt` → use `formatting-test-cases.json`
- [ ] Migrate `CurrencyFormatterTests.swift` → use `formatting-test-cases.json`

### Phase 3: Cleanup
- [ ] Run all tests (verify everything passes)
- [ ] Remove old hardcoded test data
- [ ] Update documentation
- [ ] Commit changes

---

## 🧪 **Testing the Migration**

### Android

```bash
cd android
./gradlew testDebugUnitTest --tests "*VoiceCurrencyDetectorRefactoredTest"
```

### iOS

```bash
cd ios/JustSpent
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:JustSpentTests/VoiceCurrencyDetectorRefactoredTests
```

---

## 💡 **Pro Tips**

1. **Keep a Few Legacy Tests**: Don't delete ALL old tests immediately. Keep 2-3 as regression tests.

2. **Gradual Migration**: You don't have to migrate everything at once:
   - Start with voice tests (biggest impact)
   - Then UI test data
   - Finally formatting/validation tests

3. **Test As You Go**: After migrating each file, run tests to ensure nothing broke.

4. **Document Patterns**: If you create new test patterns, document them in README.md.

5. **Version JSON Files**: When updating test data, increment the `version` field in JSON.

---

## 🎓 **Learning Resources**

- **JSON Test Data**: See `shared/test-data/README.md`
- **Loader Examples**: See `SharedTestDataLoader.kt` and `.swift`
- **Refactored Tests**: See `*RefactoredTest.kt` and `*RefactoredTests.swift`
- **Data Structure**: See JSON files in `shared/test-data/`

---

## ❓ **FAQ**

**Q: Do I have to delete the old test files?**
A: No! You can keep both during migration. Once refactored tests pass, you can remove old files.

**Q: What if I need platform-specific test data?**
A: Keep platform-specific data in platform folders. Use shared JSON for common cases (90% of tests).

**Q: Can I still add new test cases in code?**
A: Yes, but prefer adding to JSON. Only use code for truly unique/complex tests.

**Q: How do I debug failing JSON-based tests?**
A: The loader prints test IDs. Find the failing ID in JSON, check the input/expected values.

---

**Ready to migrate? Start with the voice tests - they have the biggest impact!** 🚀

---

**Last Updated**: January 29, 2025
**Version**: 1.0.0
**Status**: Ready for Migration
