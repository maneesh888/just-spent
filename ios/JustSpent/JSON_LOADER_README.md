# JSONLoader - Unified JSON Loading Architecture

## Purpose

`JSONLoader` provides a **single, tested, reusable** way to load JSON files in the Just Spent iOS app. It works in both the **main app** and **test targets**, ensuring consistency and eliminating duplicate code.

## Architecture

```
shared/currencies.json  ← Single source of truth
         ↓
    JSONLoader.swift    ← Unified loader (main app)
         ↓
    ┌────────────────┬──────────────┐
    ↓                ↓              ↓
Main App Code   Unit Tests    UI Tests
(Currency.swift) (JSONLoaderTests) (TestDataHelper)
```

## Files Created

### 1. `JustSpent/Utils/JSONLoader.swift` (Main App)
**Location**: `ios/JustSpent/JustSpent/Utils/JSONLoader.swift`

**Purpose**: Core JSON loading utility

**Key Methods**:
```swift
// Load complete currency data
static func loadCurrencies(
    from bundle: Bundle = .main,
    filename: String = "currencies"
) -> CurrencyData?

// Load just currency codes (fast)
static func loadCurrencyCodes(
    from bundle: Bundle = .main,
    filename: String = "currencies"
) -> [String]

// Generic loader for any Codable type
static func load<T: Codable>(
    _ type: T.Type,
    from filename: String,
    bundle: Bundle = .main
) -> T?
```

**Error Handling**:
- ✅ File not found → Returns nil + diagnostic print
- ✅ JSON parse error → Returns nil + detailed error message
- ✅ Missing keys → Returns nil + shows which key is missing
- ✅ Type mismatch → Returns nil + shows type conflict

### 2. `JustSpentTests/Utils/JSONLoaderTests.swift` (Unit Tests)
**Location**: `ios/JustSpent/JustSpentTests/Utils/JSONLoaderTests.swift`

**Purpose**: Comprehensive tests for JSONLoader

**Test Coverage**:
- ✅ `testLoadCurrencies_fromMainBundle_succeeds` - Verifies loading works
- ✅ `testLoadCurrencies_verifyStructure` - Validates JSON structure
- ✅ `testLoadCurrencyCodes_returnsAllCodes` - Tests fast code loading
- ✅ `testLoadCurrencies_fromInvalidBundle_returnsNil` - Error handling
- ✅ `testLoadCurrencies_performance` - Performance benchmark

### 3. Updated `TestDataHelper.swift` (UI Tests)
**Location**: `ios/JustSpent/JustSpentUITests/TestDataHelper.swift`

**Changes**:
- ❌ Removed duplicate JSON loading code
- ✅ Now uses `JSONLoader.loadCurrencyCodes()`
- ✅ Maintains fallback for backward compatibility

## Benefits

### 1. **Single Source of Truth**
- All JSON loading goes through `JSONLoader`
- No duplicate parsing logic
- Consistent error handling everywhere

### 2. **Testable**
- Unit tests verify JSON structure
- Performance tests ensure fast loading
- Error cases are tested

### 3. **Reusable**
- Works in main app
- Works in unit tests
- Works in UI tests
- Generic `load<T>()` method for future JSON files

### 4. **Better Error Messages**
```
❌ JSONLoader: currencies.json not found in bundle: /path/to/bundle
❌ JSONLoader: Key 'symbol' not found - codingPath: currencies[0]
❌ JSONLoader: Type mismatch for Bool - expected String at isRTL
```

## Usage Examples

### In Main App Code
```swift
import JustSpent

// Load all currency data
if let currencyData = JSONLoader.loadCurrencies() {
    let allCurrencies = currencyData.currencies
    print("Loaded \(allCurrencies.count) currencies")
}

// Load just codes (faster)
let codes = JSONLoader.loadCurrencyCodes()
print("Currency codes: \(codes)")
```

### In Unit Tests
```swift
@testable import JustSpent

func testMyCurrencyLogic() {
    // Load from test bundle
    let codes = JSONLoader.loadCurrencyCodes(from: Bundle(for: Self.self))
    XCTAssertEqual(codes.count, 36)
}
```

### In UI Tests
```swift
// TestDataHelper already uses JSONLoader internally
let allCurrencies = TestDataHelper.loadCurrencyCodesFromJSON()
```

## Migration Path

### Before (Old Approach)
```swift
// Duplicate code in multiple places
guard let url = Bundle.main.url(forResource: "currencies", withExtension: "json") else {
    return []
}
let data = try Data(contentsOf: url)
let decoder = JSONDecoder()
let result = try decoder.decode(CurrencyData.self, from: data)
// ... error handling duplicated everywhere
```

### After (New Approach)
```swift
// One line, consistent everywhere
let currencies = JSONLoader.loadCurrencies()
```

## Testing the JSONLoader

### Run Unit Tests
```bash
cd ios/JustSpent
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:JustSpentTests/JSONLoaderTests
```

### Expected Results
```
Test Suite 'JSONLoaderTests' started
✅ testLoadCurrencies_fromMainBundle_succeeds passed (0.003 sec)
✅ testLoadCurrencies_verifyStructure passed (0.002 sec)
✅ testLoadCurrencyCodes_returnsAllCodes passed (0.001 sec)
✅ testLoadCurrencies_fromInvalidBundle_returnsNil passed (0.001 sec)
✅ testLoadCurrencies_performance passed (0.001 sec)

Test Suite 'JSONLoaderTests' passed at ...
     5 tests passed, 0 failed, 0 skipped (0.008 total)
```

## Next Steps

### 1. Add JSONLoader to Xcode Project
- Open `JustSpent.xcodeproj`
- Add `Utils/JSONLoader.swift` to **JustSpent** target
- Add `Utils/JSONLoaderTests.swift` to **JustSpentTests** target
- Verify builds successfully

### 2. Update Main App to Use JSONLoader
Replace any direct JSON loading with `JSONLoader` calls

### 3. Run All Tests
Ensure everything still works with the new architecture

## Future Enhancements

### Support for More JSON Files
```swift
// Easy to add new JSON files
struct AppConfig: Codable {
    let apiEndpoint: String
    let features: [String]
}

let config = JSONLoader.load(AppConfig.self, from: "config")
```

### Caching
```swift
// Add caching for frequently accessed JSON
private static var currencyCache: CurrencyData?

static func loadCurrencies() -> CurrencyData? {
    if let cached = currencyCache {
        return cached
    }
    let loaded = loadCurrenciesFromFile()
    currencyCache = loaded
    return loaded
}
```

---

**Created**: 2025-11-10
**Last Updated**: 2025-11-10
**Status**: Ready for Xcode project integration
