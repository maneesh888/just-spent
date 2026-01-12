# Just Spent - Multi-Currency Architecture

## 🎯 Overview

This document defines the **approved multi-currency tabbed UI architecture** for Just Spent, replacing the original single-list design with a currency-isolated tabbed interface.

**Last Updated:** 2025-10-19
**Status:** ✅ APPROVED - Implementation In Progress

---

## 📐 Design Principles

### Core Requirements
1. **Dynamic currency-based lists** - Separate lists based on currencies that exist in expenses
2. **Conditional UI** - Show tabs only when multiple currencies exist; single list when only one currency
3. **Tab switcher** - Switchable interface at top to navigate between currency lists (when multiple exist)
4. **Universal currency support** - Support ANY currency detected by voice (not limited to 6 predefined)
5. **Predefined + Dynamic** - Start with 6 common currencies (AED, USD, EUR, GBP, INR, SAR), allow any additional via voice
6. **Onboarding with permissions** - Mandatory default currency selection + permission handler on first launch
7. **Default fallback** - Use default currency when voice command doesn't specify currency
8. **Unified UI structure** - Each currency view uses identical expense list + total layout
9. **Shared voice button** - Single floating action button works across all currency screens

### User Experience Flow

```
First Launch:
  App Launch → Onboarding Screen → Request Permissions (Siri/Assistant, Mic, Notifications)
    ↓
  Select Default Currency → Save Preferences → Main App

Subsequent Launches - Single Currency:
  App Launch → Single List View (No Tabs) → Show Default Currency Expenses

Subsequent Launches - Multiple Currencies:
  App Launch → Tabbed Interface → Show Last Viewed Currency

Voice Command with Currency:
  "50 dirhams groceries" → Detect AED
    ↓
  If AED tab exists → Navigate to AED, add expense
  If no AED tab → Create AED list, add expense, show tab if multiple currencies now exist

Voice Command without Currency:
  "50 groceries" → Use Default Currency → Add to Default Currency List

Voice Command with New Currency:
  "100 Croatian kuna dinner" → Detect HRK (new currency)
    ↓
  Create HRK in database → Add expense → Update UI (show tabs if now multiple currencies)
```

---

## 🏗️ UI Architecture

### Conditional UI - Single Currency (No Tabs)

```
Scenario: Only AED expenses exist
┌─────────────────────────────────────────────────────────┐
│  Just Spent                                      ⚙️     │  ← No tabs shown
├─────────────────────────────────────────────────────────┤
│  Total Spent This Month                                 │
│  AED 5,234.50                                          │
├─────────────────────────────────────────────────────────┤
│  Expense List                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📝 AED 150.00 - Grocery          Oct 18, 2025  │   │
│  │  📝 AED 50.00 - Food & Dining     Oct 18, 2025  │   │
│  │  📝 AED 200.00 - Transportation   Oct 17, 2025  │   │
│  │  📝 AED 75.00 - Entertainment     Oct 16, 2025  │   │
│  │  ...                                            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│                                          ┌────────┐     │
│                                          │   🎤   │     │
│                                          │ Voice  │     │
│                                          └────────┘     │
└─────────────────────────────────────────────────────────┘
```

### Conditional UI - Multiple Currencies (With Tabs)

```
Scenario: AED + USD + EUR expenses exist
┌─────────────────────────────────────────────────────────┐
│  Tab Switcher                                    ⚙️     │
│  ┌─────┐ ┌─────┐ ┌─────┐                              │
│  │ AED │ │ USD │ │ EUR │  ←  Switchable tabs          │
│  └─────┘ └─────┘ └─────┘                              │
├─────────────────────────────────────────────────────────┤
│  Total Spent This Month                                 │
│  AED 5,234.50                                          │
├─────────────────────────────────────────────────────────┤
│  Expense List (Filtered by Currency)                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │  📝 AED 150.00 - Grocery          Oct 18, 2025  │   │
│  │  📝 AED 50.00 - Food & Dining     Oct 18, 2025  │   │
│  │  📝 AED 200.00 - Transportation   Oct 17, 2025  │   │
│  │  📝 AED 75.00 - Entertainment     Oct 16, 2025  │   │
│  │  ...                                            │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│                                          ┌────────┐     │
│                                          │   🎤   │     │
│                                          │ Voice  │     │
│                                          └────────┘     │
└─────────────────────────────────────────────────────────┘
```

### Dynamic Tab Creation

```
Voice: "100 Croatian kuna on dinner"
  ↓
Detect: HRK (Croatian Kuna) - New currency!
  ↓
Before: [AED] [USD] [EUR]
After:  [AED] [USD] [EUR] [HRK]  ← New tab appears
```

### Component Structure with Conditional UI

**iOS (SwiftUI):**
```swift
// Main app structure with conditional UI
ContentView
├── if !onboardingComplete
│   └── CurrencyOnboardingView (with permission requests)
└── else
    ├── if activeCurrencies.count == 1
    │   └── SingleCurrencyView
    │       ├── NavigationBar (no tabs)
    │       ├── TotalHeaderView(currency: activeCurrencies[0])
    │       ├── ExpenseListView(currency: activeCurrencies[0])
    │       └── VoiceActionButton (shared)
    └── else (activeCurrencies.count > 1)
        └── MultiCurrencyTabbedView
            ├── ScrollableTabBar(currencies: activeCurrencies)
            └── TabView(selection: selectedCurrency)
                ├── CurrencyExpenseView(currency: activeCurrencies[0])
                │   ├── TotalHeaderView(currency: ...)
                │   └── ExpenseListView(currency: ...)
                ├── CurrencyExpenseView(currency: activeCurrencies[1])
                │   ├── TotalHeaderView(currency: ...)
                │   └── ExpenseListView(currency: ...)
                └── VoiceActionButton (shared across all tabs)
```

**Android (Jetpack Compose):**
```kotlin
// Main app structure with conditional UI
MainScreen
├── if (!onboardingComplete)
│   └── CurrencyOnboardingScreen (with permission requests)
└── else
    ├── if (activeCurrencies.size == 1)
    │   └── SingleCurrencyScreen
    │       ├── TopAppBar (no tabs)
    │       ├── TotalHeader(currency = activeCurrencies[0])
    │       ├── ExpenseList(currency = activeCurrencies[0])
    │       └── FloatingActionButton (voice, shared)
    └── else (activeCurrencies.size > 1)
        └── MultiCurrencyTabbedScreen
            ├── ScrollableTabRow(currencies = activeCurrencies)
            └── HorizontalPager(pageCount = activeCurrencies.size)
                ├── CurrencyExpenseScreen(currency = activeCurrencies[0])
                │   ├── TotalHeader(currency = ...)
                │   └── ExpenseList(currency = ...)
                ├── CurrencyExpenseScreen(currency = activeCurrencies[1])
                │   ├── TotalHeader(currency = ...)
                │   └── ExpenseList(currency = ...)
                └── FloatingActionButton (voice, shared across all tabs)
```

**Conditional Rendering Logic:**
```swift
// iOS
@Published var activeCurrencies: [Currency] = []

var shouldShowTabs: Bool {
    return activeCurrencies.count > 1
}

var body: some View {
    if shouldShowTabs {
        MultiCurrencyTabbedView(currencies: activeCurrencies)
    } else if let currency = activeCurrencies.first {
        SingleCurrencyView(currency: currency)
    } else {
        EmptyStateView() // No expenses yet
    }
}
```

```kotlin
// Android
val activeCurrencies by viewModel.activeCurrencies.collectAsState()

when {
    activeCurrencies.size > 1 -> MultiCurrencyTabbedScreen(activeCurrencies)
    activeCurrencies.size == 1 -> SingleCurrencyScreen(activeCurrencies.first())
    else -> EmptyStateView() // No expenses yet
}
```

---

## 🎬 Onboarding Flow

### First Launch Requirements

**Purpose:** Establish default currency AND request necessary permissions before allowing app access

**Onboarding Steps:**
1. **Welcome Screen** - App introduction
2. **Permission Requests** - Siri/Google Assistant, Microphone, Notifications (optional)
3. **Currency Selection** - Choose default currency from list
4. **Completion** - Save preferences and navigate to main app

**UI Components:**
- Full-screen welcome message
- Permission request cards (Siri/Assistant, Mic, Notifications)
- Large, recognizable currency symbols (د.إ, $, €, £, ₹, ﷼) for 6 predefined currencies
- Currency name + code display
- Radio-style selection indicator
- Helper text explaining default currency purpose
- Continue button (disabled until currency selected)

### Implementation Details

**iOS with Permissions:**
```swift
// File: CurrencyOnboardingView.swift
import Intents

struct CurrencyOnboardingView: View {
    @State private var selectedCurrency: Currency = .default
    @State private var currentStep: OnboardingStep = .welcome
    @State private var siriAuthorized = false
    @State private var micAuthorized = false
    @State private var notificationsAuthorized = false
    @Binding var isOnboardingComplete: Bool

    enum OnboardingStep {
        case welcome
        case permissions
        case currencySelection
    }

    var body: some View {
        switch currentStep {
        case .welcome:
            WelcomeView(onContinue: { currentStep = .permissions })
        case .permissions:
            PermissionsView(
                onContinue: { currentStep = .currencySelection },
                siriAuthorized: $siriAuthorized,
                micAuthorized: $micAuthorized,
                notificationsAuthorized: $notificationsAuthorized
            )
        case .currencySelection:
            CurrencySelectionView(
                selectedCurrency: $selectedCurrency,
                onContinue: completeOnboarding
            )
        }
    }

    private func completeOnboarding() {
        UserPreferences.shared.setDefaultCurrency(selectedCurrency)
        UserPreferences.shared.completeOnboarding()
        isOnboardingComplete = true
    }
}

struct PermissionsView: View {
    let onContinue: () -> Void
    @Binding var siriAuthorized: Bool
    @Binding var micAuthorized: Bool
    @Binding var notificationsAuthorized: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Enable Features")
                .font(.largeTitle)

            // Siri Permission
            PermissionCard(
                title: "Siri Shortcuts",
                description: "Log expenses with voice commands",
                icon: "mic.fill",
                isAuthorized: siriAuthorized,
                action: requestSiriPermission
            )

            // Microphone Permission
            PermissionCard(
                title: "Microphone Access",
                description: "Required for voice expense logging",
                icon: "waveform",
                isAuthorized: micAuthorized,
                action: requestMicPermission
            )

            // Notifications Permission (Optional)
            PermissionCard(
                title: "Notifications",
                description: "Get budget alerts and reminders",
                icon: "bell.fill",
                isAuthorized: notificationsAuthorized,
                action: requestNotificationPermission,
                optional: true
            )

            Button("Continue", action: onContinue)
                .disabled(!micAuthorized) // Mic is required minimum
        }
    }

    private func requestSiriPermission() {
        INPreferences.requestSiriAuthorization { status in
            DispatchQueue.main.async {
                siriAuthorized = (status == .authorized)
            }
        }
    }

    private func requestMicPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                micAuthorized = granted
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsAuthorized = granted
            }
        }
    }
}
```

**Android with Permissions:**
```kotlin
// File: CurrencyOnboardingScreen.kt
import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.*

enum class OnboardingStep {
    WELCOME,
    PERMISSIONS,
    CURRENCY_SELECTION
}

@Composable
fun CurrencyOnboardingScreen(
    onCurrencySelected: (Currency) -> Unit,
    onComplete: () -> Unit
) {
    var currentStep by remember { mutableStateOf(OnboardingStep.WELCOME) }
    var selectedCurrency by remember { mutableStateOf(Currency.default) }
    var micPermissionGranted by remember { mutableStateOf(false) }
    var notificationPermissionGranted by remember { mutableStateOf(false) }

    when (currentStep) {
        OnboardingStep.WELCOME -> {
            WelcomeScreen(onContinue = { currentStep = OnboardingStep.PERMISSIONS })
        }
        OnboardingStep.PERMISSIONS -> {
            PermissionsScreen(
                onContinue = { currentStep = OnboardingStep.CURRENCY_SELECTION },
                micPermissionGranted = micPermissionGranted,
                onMicPermissionResult = { micPermissionGranted = it },
                notificationPermissionGranted = notificationPermissionGranted,
                onNotificationPermissionResult = { notificationPermissionGranted = it }
            )
        }
        OnboardingStep.CURRENCY_SELECTION -> {
            CurrencySelectionScreen(
                selectedCurrency = selectedCurrency,
                onCurrencySelected = { selectedCurrency = it },
                onContinue = {
                    onCurrencySelected(selectedCurrency)
                    onComplete()
                }
            )
        }
    }
}

@Composable
fun PermissionsScreen(
    onContinue: () -> Void,
    micPermissionGranted: Boolean,
    onMicPermissionResult: (Boolean) -> Unit,
    notificationPermissionGranted: Boolean,
    onNotificationPermissionResult: (Boolean) -> Unit
) {
    // Microphone Permission Launcher
    val micPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted -> onMicPermissionResult(isGranted) }

    // Notification Permission Launcher (Android 13+)
    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted -> onNotificationPermissionResult(isGranted) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Text(
            text = "Enable Features",
            style = MaterialTheme.typography.headlineLarge
        )

        // Google Assistant Permission
        PermissionCard(
            title = "Google Assistant",
            description = "Log expenses with voice commands",
            icon = Icons.Default.Assistant,
            isGranted = true, // Handled via App Actions
            onRequest = { /* No runtime permission needed */ },
            optional = false
        )

        // Microphone Permission
        PermissionCard(
            title = "Microphone Access",
            description = "Required for voice expense logging",
            icon = Icons.Default.Mic,
            isGranted = micPermissionGranted,
            onRequest = {
                micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
            },
            optional = false
        )

        // Notification Permission (Optional)
        PermissionCard(
            title = "Notifications",
            description = "Get budget alerts and reminders",
            icon = Icons.Default.Notifications,
            isGranted = notificationPermissionGranted,
            onRequest = {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            },
            optional = true
        )

        Button(
            onClick = onContinue,
            enabled = micPermissionGranted, // Mic is required minimum
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Continue")
        }
    }
}
```

### State Management

**iOS (UserDefaults):**
```swift
// UserPreferences.swift
private enum Keys {
    static let defaultCurrency = "user_default_currency"
    static let hasCompletedOnboarding = "user_has_completed_onboarding"
}

func hasCompletedOnboarding() -> Bool {
    return UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
}

func completeOnboarding() {
    UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
}
```

**Android (DataStore):**
```kotlin
// UserPreferencesRepository.kt
companion object {
    private val HAS_COMPLETED_ONBOARDING_KEY =
        stringPreferencesKey("has_completed_onboarding")
}

val hasCompletedOnboarding: Flow<Boolean> =
    context.dataStore.data.map { preferences ->
        preferences[HAS_COMPLETED_ONBOARDING_KEY]?.toBoolean() ?: false
    }

suspend fun completeOnboarding() {
    context.dataStore.edit { preferences ->
        preferences[HAS_COMPLETED_ONBOARDING_KEY] = "true"
    }
}
```

---

## 💱 Currency Tab Management

### Dynamic Tab Generation

**Logic:**
1. Query database for distinct currencies: `SELECT DISTINCT currency FROM expenses`
2. Always include default currency even if no expenses
3. Sort tabs: Default currency first, then alphabetically
4. Create tab for each currency with expense count > 0

**iOS Implementation:**
```swift
@Published var activeCurrencies: [Currency] = []

func loadActiveCurrencies() {
    let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "Expense")
    request.resultType = .dictionaryResultType
    request.propertiesToFetch = ["currency"]
    request.returnsDistinctResults = true

    do {
        let results = try context.fetch(request)
        var currencies = results.compactMap { dict in
            guard let code = dict["currency"] as? String else { return nil }
            return Currency.fromCode(code)
        }

        // Always include default currency
        let defaultCurrency = UserPreferences.shared.defaultCurrency
        if !currencies.contains(defaultCurrency) {
            currencies.insert(defaultCurrency, at: 0)
        }

        activeCurrencies = currencies.sorted {
            $0 == defaultCurrency ? true : $1 == defaultCurrency ? false : $0.code < $1.code
        }
    } catch {
        activeCurrencies = [UserPreferences.shared.defaultCurrency]
    }
}
```

**Android Implementation:**
```kotlin
// ExpenseRepository.kt
@Query("SELECT DISTINCT currency FROM expenses ORDER BY currency")
fun getDistinctCurrencies(): Flow<List<String>>

// ViewModel
val activeCurrencies: StateFlow<List<Currency>> =
    expenseRepository.getDistinctCurrencies()
        .map { codes ->
            val currencies = codes.mapNotNull { Currency.fromCode(it) }.toMutableList()
            val defaultCurrency = userPreferences.getCurrentCurrency()

            // Always include default
            if (!currencies.contains(defaultCurrency)) {
                currencies.add(0, defaultCurrency)
            }

            // Sort: default first, then alphabetically
            currencies.sortedWith(
                compareBy(
                    { it != defaultCurrency },
                    { it.code }
                )
            )
        }
        .stateIn(viewModelScope, SharingStarted.Lazily, listOf(defaultCurrency))
```

### Tab Selection & Navigation

**Rules:**
1. **Default Tab:** Open to default currency on fresh launch
2. **Last Viewed:** Remember last selected tab across sessions
3. **Voice Addition:** Navigate to currency tab when voice expense added
4. **Manual Navigation:** User swipes/taps between tabs freely

**Persistence:**
```swift
// iOS
@AppStorage("lastViewedCurrency") var lastViewedCurrency: String = Currency.default.code
```

```kotlin
// Android
suspend fun saveLastViewedCurrency(currency: Currency) {
    dataStore.edit { preferences ->
        preferences[LAST_VIEWED_CURRENCY_KEY] = currency.code
    }
}
```

---

## 🎤 Voice Integration

### Currency Detection Flow

```
Voice Input: "I just spent 50 dirhams on groceries"
      ↓
VoiceCurrencyDetector.extractAmountAndCurrency(transcript)
      ↓
Extracted: { amount: 50.0, currency: AED }
      ↓
Check if AED tab exists
      ├─ YES → Navigate to AED tab
      └─ NO  → Create AED tab, then navigate
      ↓
Add expense with currency = AED
      ↓
Reload expenses for AED tab
      ↓
Update total for AED tab
      ↓
Show success confirmation
```

### Default Currency Fallback

```
Voice Input: "I just spent 50 on groceries" (no currency)
      ↓
VoiceCurrencyDetector.detectCurrency(transcript, defaultCurrency)
      ↓
No currency detected → Return defaultCurrency
      ↓
Add expense with currency = defaultCurrency
      ↓
Navigate to default currency tab
      ↓
Show confirmation with currency
```

### Voice Detection Patterns

**Predefined Currency Keywords (6 Common):**
```yaml
AED:
  keywords: ["dirham", "dirhams", "dhs", "aed", "د.إ"]
  symbols: ["د.إ", "AED"]

USD:
  keywords: ["dollar", "dollars", "buck", "bucks", "usd", "$"]
  symbols: ["$", "USD"]

EUR:
  keywords: ["euro", "euros", "eur", "€"]
  symbols: ["€", "EUR"]

GBP:
  keywords: ["pound", "pounds", "sterling", "quid", "gbp", "£"]
  symbols: ["£", "GBP"]

INR:
  keywords: ["rupee", "rupees", "inr", "₹"]
  symbols: ["₹", "INR"]

SAR:
  keywords: ["riyal", "riyals", "sar", "﷼"]
  symbols: ["﷼", "SAR"]
```

### Universal Currency Support

**Approach:** Predefined (6 common) + Dynamic (any ISO 4217)

**Detection Strategy:**
1. **Check Predefined Keywords** - Match against 6 common currencies first
2. **Check ISO 4217 Codes** - Match 3-letter currency codes (HRK, JPY, CNY, etc.)
3. **Check Currency Symbols** - Match symbols from extended currency symbol map
4. **Fallback to Default** - If no match, use user's default currency

**Dynamic Currency Creation:**
```
Voice: "100 Croatian kuna on dinner"
  ↓
Parse: "Croatian kuna" → Lookup ISO 4217 → "HRK"
  ↓
Check: Is HRK in Currency enum/class?
  ├─ NO → Create dynamic Currency(code: "HRK", symbol: "kn", name: "Croatian Kuna")
  └─ YES → Use existing HRK
  ↓
Add to database with currency = "HRK"
  ↓
UI updates: New HRK tab appears (if multiple currencies now exist)
```

**Extended Currency Detection:**
```swift
// iOS - Universal Currency Detection
extension Currency {
    static func fromVoice(_ text: String) -> Currency? {
        // 1. Check predefined (fast path)
        if let predefined = detectPredefined(text) {
            return predefined
        }

        // 2. Check ISO 4217 codes
        if let iso = extractISO4217Code(text) {
            return fromCode(iso) ?? createDynamic(code: iso)
        }

        // 3. Check currency names
        if let name = extractCurrencyName(text) {
            return fromName(name) ?? nil
        }

        return nil
    }

    private static func createDynamic(code: String) -> Currency? {
        guard let info = ISO4217.lookup(code) else { return nil }
        return Currency(
            code: code,
            symbol: info.symbol,
            displayName: info.name,
            isRTL: info.isRTL
        )
    }
}
```

**ISO 4217 Support:**
- All 180+ ISO 4217 currency codes supported
- Dynamic formatting based on currency code
- Symbol fallback: Use code if symbol unknown (e.g., "HRK" instead of "kn")
- Locale-aware number formatting per currency

### Shared Voice Button

**Behavior:**
- Floating action button visible on all tabs
- Single button instance, state managed globally
- Voice result navigates to appropriate currency tab
- Visual feedback during processing
- Error handling shows on current tab

**iOS:**
```swift
// Shared across all tabs
struct VoiceActionButton: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @State private var isListening = false

    var body: some View {
        Button(action: startVoiceRecording) {
            Image(systemName: isListening ? "mic.fill" : "mic")
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }

    private func startVoiceRecording() {
        // Voice recording logic
        // On success, navigate to appropriate currency tab
    }
}
```

---

## 📊 Data Layer Integration

### Per-Currency Queries

**iOS Core Data Predicates:**
```swift
// Fetch expenses for specific currency
let predicate = NSPredicate(format: "currency == %@", currency.code)

// Calculate total for currency
let sumDescription = NSExpressionDescription()
sumDescription.name = "sum"
sumDescription.expression = NSExpression(forFunction: "sum:",
                                         arguments: [NSExpression(forKeyPath: "amount")])
sumDescription.expressionResultType = .decimalAttributeType
```

**Android Room Queries:**
```kotlin
@Dao
interface ExpenseDao {
    // Get expenses for currency tab
    @Query("SELECT * FROM expenses WHERE currency = :currency ORDER BY transactionDate DESC")
    fun getExpensesByCurrency(currency: String): Flow<List<Expense>>

    // Calculate total for currency tab
    @Query("SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE currency = :currency")
    fun getTotalByCurrency(currency: String): Flow<BigDecimal>

    // Get distinct currencies for tab generation
    @Query("SELECT DISTINCT currency FROM expenses ORDER BY currency")
    fun getDistinctCurrencies(): Flow<List<String>>

    // Get expense count per currency
    @Query("SELECT currency, COUNT(*) as count FROM expenses GROUP BY currency")
    fun getCurrencyCounts(): Flow<Map<String, Int>>
}
```

### ViewModel Structure

**iOS:**
```swift
class ExpenseViewModel: ObservableObject {
    @Published var expensesByCurrency: [Currency: [Expense]] = [:]
    @Published var totalsByCurrency: [Currency: Decimal] = [:]
    @Published var activeCurrencies: [Currency] = []
    @Published var selectedCurrency: Currency

    init() {
        self.selectedCurrency = UserPreferences.shared.defaultCurrency
        loadActiveCurrencies()
        loadAllData()
    }

    func expenses(for currency: Currency) -> [Expense] {
        return expensesByCurrency[currency] ?? []
    }

    func total(for currency: Currency) -> Decimal {
        return totalsByCurrency[currency] ?? 0
    }
}
```

**Android:**
```kotlin
class ExpenseViewModel(
    private val expenseRepository: ExpenseRepository,
    private val userPreferences: UserPreferences
) : ViewModel() {

    val selectedCurrency = MutableStateFlow(userPreferences.defaultCurrency)

    val activeCurrencies: StateFlow<List<Currency>> =
        expenseRepository.getDistinctCurrencies()
            .map { /* transform to Currency objects */ }
            .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

    fun getExpenses(currency: Currency): Flow<List<Expense>> {
        return expenseRepository.getExpensesByCurrency(currency.code)
    }

    fun getTotal(currency: Currency): Flow<BigDecimal> {
        return expenseRepository.getTotalByCurrency(currency.code)
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests

**Currency Tab Logic:**
```swift
// iOS
func testActiveCurrenciesIncludesDefault() {
    // Given: No expenses in database
    // When: Loading active currencies
    // Then: Default currency should be included
}

func testDynamicTabCreation() {
    // Given: Expenses in AED and USD
    // When: Loading active currencies
    // Then: Should show AED and USD tabs
}
```

```kotlin
// Android
@Test
fun testCurrencyFiltering() {
    // Given: Expenses in multiple currencies
    // When: Querying by specific currency
    // Then: Should return only expenses in that currency
}
```

### Integration Tests

**Onboarding Flow:**
- Test first launch shows onboarding
- Test currency selection saves correctly
- Test navigation to main app after completion
- Test subsequent launches skip onboarding

**Tab Navigation:**
- Test tab creation on new currency
- Test tab switching preserves state
- Test voice navigation to correct tab
- Test empty state handling

### UI Tests

**iOS (XCUITest):**
```swift
func testOnboardingToCurrencyTabs() {
    // Launch app first time
    // Complete onboarding
    // Verify main tabbed interface shown
    // Verify default currency tab selected
}
```

**Android (Espresso/Compose Testing):**
```kotlin
@Test
fun testCurrencyTabNavigation() {
    // Given: Multiple currency tabs
    // When: Swiping between tabs
    // Then: Each tab shows correct currency data
}
```

---

## 🚀 Implementation Checklist

### Phase 1: Onboarding ✅
- [x] Create CurrencyOnboardingView (iOS)
- [x] Create CurrencyOnboardingScreen (Android)
- [x] Add hasCompletedOnboarding flag (iOS & Android)
- [ ] **IN PROGRESS**: Implement navigation logic on app launch

### Phase 2: Tab Infrastructure ⏳
- [ ] Build scrollable tab bar (iOS & Android)
- [ ] Implement dynamic tab generation
- [ ] Add tab selection persistence
- [ ] Create tab switching animations

### Phase 3: Per-Currency Views ⏳
- [ ] Implement currency filtering in queries
- [ ] Build per-currency total calculation
- [ ] Create reusable expense list component
- [ ] Add empty state handling

### Phase 4: Voice Integration ⏳
- [ ] Update voice detection for currency
- [ ] Implement tab navigation on voice add
- [ ] Handle default currency fallback
- [ ] Add voice confirmation UI

### Phase 5: Testing & Polish ⏳
- [ ] Write unit tests for tab logic
- [ ] Integration tests for onboarding
- [ ] UI tests for navigation
- [ ] Performance testing with multiple currencies
- [ ] Accessibility testing

---

## 📚 Related Documentation

- **CLAUDE.md** - Updated with multi-currency architecture overview
- **just-spent-master-plan.md** - Updated technical architecture section
- **data-models-spec.md** - Added multi-currency UI architecture section
- **CURRENCY_IMPLEMENTATION_GUIDE.md** - Original currency features (voice detection, formatting)

---

## 🔄 Migration Notes

**From Original Design:**
- **Removed:** Currency badges in expense rows
- **Removed:** "All Expenses" view with mixed currencies
- **Removed:** Currency conversion in single list
- **Changed:** Single list → Multiple currency-specific tabs
- **Changed:** Settings-based currency selection → Onboarding-first
- **Added:** Dynamic tab generation
- **Added:** Mandatory onboarding flow
- **Added:** Per-currency totals

**Data Model Changes:**
- No database schema changes required
- `currency` field already exists in Expense entity
- Queries now filter by currency instead of converting
- No migration scripts needed

---

*This architecture ensures clear currency separation, intuitive navigation, and seamless voice integration across both platforms.*
