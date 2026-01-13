# Just Spent - Shared Test Data

## Overview

This directory contains consolidated test data used across both iOS and Android platforms. The goal is to maintain a **single source of truth** for all test scenarios, eliminating duplication and ensuring consistency.

## 📁 File Structure

```
shared/test-data/
├── voice-test-data.json              # Voice recognition test cases (200+ tests)
├── test-expenses.json                # Sample expenses for UI tests
├── currency-reference.json           # 36 currencies with metadata
├── category-reference.json           # Categories with voice keywords
├── formatting-test-cases.json        # Currency formatting expectations
├── validation-rules.json             # Input validation constraints
├── error-scenarios.json              # Error handling test cases
└── README.md                         # This file
```

## 📄 File Descriptions

### 1. `voice-test-data.json`

**Purpose:** Comprehensive test cases for voice recognition and currency detection.

**Contents:**
- **currency_detection**: 70+ test cases covering all 36 currencies
- **amount_extraction**: Edge cases for amount parsing
- **written_numbers**: Spelled-out number detection
- **real_world_scenarios**: Practical voice command patterns
- **edge_cases**: Empty strings, whitespace, multiple currencies
- **symbol_normalization**: Currency symbol to code conversion
- **disambiguation**: Tests for similar currency names

**Usage:**
```kotlin
// Android
val testData = loadJson("shared/test-data/voice-test-data.json")
testData.test_suites.currency_detection.tests.forEach { test ->
    val result = VoiceCurrencyDetector.detectCurrency(test.input)
    assertEquals(test.expected_currency, result)
}
```

```swift
// iOS
let testData = loadJSON("shared/test-data/voice-test-data.json")
for test in testData["test_suites"]["currency_detection"]["tests"] {
    let result = detector.detectCurrency(from: test["input"])
    XCTAssertEqual(test["expected_currency"], result)
}
```

### 2. `test-expenses.json`

**Purpose:** Pre-defined expense data for UI and integration tests.

**Contents:**
- **single_currency_aed**: 5 AED expenses (total: 650.50 AED)
- **multi_currency**: 18 expenses across 6 currencies
- **empty_state**: Empty expense list for empty state testing
- **stress_test**: Pattern for generating 100+ expenses

**Usage:**
```kotlin
// Android - Load multi-currency test set
val expenses = TestExpenseLoader.loadSet("multi_currency")
expenses.forEach { dao.insertExpense(it) }
```

```swift
// iOS - Load test expenses
let expenses = TestExpenseLoader.load(setName: "multi_currency")
expenses.forEach { context.insert($0) }
```

### 3. `currency-reference.json`

**Purpose:** Complete metadata for all 36 supported currencies.

**Contents for Each Currency:**
- ISO code, symbol, display name
- Voice keywords (e.g., "dollars", "bucks" for USD)
- Formatting rules (decimal separator, grouping)
- Common/uncommon flag
- Country codes
- Example formatted string

**Usage:**
```kotlin
// Android - Get currency metadata
val currency = CurrencyReference.get("AED")
assertEquals("د.إ", currency.symbol)
assertTrue(currency.voice_keywords.contains("dirhams"))
```

```swift
// iOS - Get currency metadata
let currency = CurrencyReference.get("AED")
XCTAssertEqual("د.إ", currency.symbol)
XCTAssertTrue(currency.voiceKeywords.contains("dirhams"))
```

### 4. `category-reference.json`

**Purpose:** Category metadata including voice keywords and merchant mappings.

**Contents for Each Category:**
- Category ID, name, icon, color
- Voice keywords for auto-categorization
- Common merchants for the category
- Sort order

**Usage:**
```kotlin
// Android - Match category from voice
val category = CategoryMatcher.match("I spent 50 on groceries")
assertEquals("grocery", category.id)
```

```swift
// iOS - Match category from voice
let category = CategoryMatcher.match("I spent 50 on groceries")
XCTAssertEqual("grocery", category.id)
```

### 5. `formatting-test-cases.json`

**Purpose:** Test cases for consistent currency formatting.

**Contents:**
- Standard formatting tests for all currencies
- Zero amounts, large amounts, small amounts
- Rounding tests
- Compact formatting (1.2K, 1.2M)
- Special cases (JPY with no decimals, BHD with 3 decimals)

**Usage:**
```kotlin
// Android - Test currency formatting
val testCase = FormattingTests.get("aed_standard")
val result = CurrencyFormatter.format(testCase.amount, Currency.AED)
assertEquals(testCase.expected_with_symbol, result)
```

```swift
// iOS - Test currency formatting
let testCase = FormattingTests.get("aed_standard")
let result = CurrencyFormatter.shared.format(amount: testCase.amount, currency: .AED)
XCTAssertEqual(testCase.expectedWithSymbol, result)
```

### 6. `validation-rules.json`

**Purpose:** Define validation constraints for all expense fields.

**Contents:**
- Amount validation (min: 0.01, max: 999,999.99)
- Currency validation (supported codes)
- Category validation (allowed values)
- Date validation (max past: 365 days, no future dates)
- Field length limits
- Test cases for valid and invalid inputs

**Usage:**
```kotlin
// Android - Validate expense
val validator = ExpenseValidator(ValidationRules.load())
val result = validator.validate(expense)
if (!result.isValid) {
    println(result.errors.joinToString())
}
```

```swift
// iOS - Validate expense
let validator = ExpenseValidator(rules: ValidationRules.load())
let result = validator.validate(expense)
XCTAssertTrue(result.isValid)
```

### 7. `error-scenarios.json`

**Purpose:** Comprehensive error scenarios for robust error handling.

**Contents:**
- **voice_recognition_errors**: No amount, incomplete command, negative amounts
- **validation_errors**: Missing required fields, invalid values
- **edge_cases**: Empty input, SQL injection attempts, emoji handling
- **permission_errors**: Microphone access denied
- **network_errors**: Sync failures, offline mode

**Usage:**
```kotlin
// Android - Test error handling
val scenario = ErrorScenarios.get("no_amount_detected")
val result = VoiceCommandProcessor.process(scenario.input)
assertEquals(scenario.expected_error_code, result.errorCode)
```

```swift
// iOS - Test error handling
let scenario = ErrorScenarios.get("no_amount_detected")
let result = VoiceCommandProcessor.process(scenario.input)
XCTAssertEqual(scenario.expectedErrorCode, result.errorCode)
```

## 🔄 Loading Test Data

### Android (Kotlin)

```kotlin
// Load JSON from shared directory
object TestDataLoader {
    fun <T> loadJSON(fileName: String, type: Class<T>): T {
        val json = File("../../shared/test-data/$fileName").readText()
        return Gson().fromJson(json, type)
    }
}

// Usage
val voiceTests = TestDataLoader.loadJSON(
    "voice-test-data.json",
    VoiceTestData::class.java
)
```

### iOS (Swift)

```swift
// Load JSON from shared directory
class TestDataLoader {
    static func loadJSON<T: Decodable>(_ fileName: String) throws -> T {
        let path = "../../shared/test-data/\(fileName)"
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Usage
let voiceTests: VoiceTestData = try TestDataLoader.loadJSON("voice-test-data.json")
```

## ✅ Benefits

### 1. **Single Source of Truth**
- Update test data once, used by both platforms
- No more sync issues between iOS and Android tests

### 2. **Reduced Code Duplication**
- **Before**: ~2,400 lines of test data
- **After**: ~300 lines of loaders
- **Reduction**: ~88% less code

### 3. **Consistency**
- Same test cases run on both platforms
- Identical error messages and validation rules
- Consistent currency formatting expectations

### 4. **Easy Maintenance**
- Add new currency once, works everywhere
- Update validation rules in one place
- Modify test cases without touching code

### 5. **Better Coverage**
- All 36 currencies tested comprehensively
- Edge cases documented and tested
- Error scenarios shared across platforms

## 🔧 Maintenance

### Adding a New Currency

1. Update `currency-reference.json`:
```json
{
  "XXX": {
    "code": "XXX",
    "symbol": "X",
    "display_name": "New Currency",
    "voice_keywords": ["new", "currency"],
    ...
  }
}
```

2. Add test cases to `voice-test-data.json`:
```json
{
  "id": "xxx_keyword",
  "input": "I spent 100 new currency",
  "expected_currency": "XXX",
  "expected_amount": 100.0
}
```

3. Add formatting test to `formatting-test-cases.json`:
```json
{
  "id": "xxx_standard",
  "amount": 1234.56,
  "currency": "XXX",
  "expected_with_symbol": "X 1,234.56"
}
```

4. Tests automatically pick up new currency on both platforms!

### Adding a New Category

1. Update `category-reference.json`:
```json
{
  "id": "new_category",
  "name": "New Category",
  "voice_keywords": ["new", "category"],
  "color": "#HEXCODE"
}
```

2. Both platforms automatically support it!

### Adding a New Test Case

1. Add to appropriate JSON file
2. Run tests on both platforms
3. No code changes needed!

## 📊 Statistics

| Metric | Value |
|--------|-------|
| **Total Test Cases** | 300+ |
| **Currencies Covered** | 36 |
| **Voice Detection Tests** | 70+ |
| **Formatting Tests** | 19 |
| **Validation Tests** | 20+ |
| **Error Scenarios** | 40+ |
| **Lines of JSON** | ~3,000 |
| **Lines Saved** | ~2,100 |

## 🎯 Coverage

- ✅ All 36 currencies with voice keywords
- ✅ All 9 expense categories
- ✅ Currency formatting edge cases
- ✅ Voice recognition edge cases
- ✅ Validation rules for all fields
- ✅ Error handling scenarios
- ✅ UI test data sets

## 🚀 Future Enhancements

- [ ] Add localization test data (Arabic, Hindi, etc.)
- [ ] Add merchant auto-categorization patterns
- [ ] Add budget rule test cases
- [ ] Add recurring expense patterns
- [ ] Add voice command variations per language

## 📝 Version History

- **1.0.0** (2025-01-29): Initial release
  - Voice test data for 36 currencies
  - Test expenses for UI tests
  - Currency and category references
  - Formatting and validation rules
  - Error scenarios

## 🤝 Contributing

When adding test data:
1. Update the appropriate JSON file
2. Increment the version number
3. Update this README with changes
4. Test on both iOS and Android
5. Commit with descriptive message

## 📞 Support

For questions or issues with test data:
- Check existing test cases for examples
- Refer to `data-models-spec.md` for schemas
- See `TESTING-GUIDE.md` for test execution

---

**Last Updated:** January 29, 2025
**Maintained By:** Development Team
**Version:** 1.0.0
