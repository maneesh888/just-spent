# Just Spent - UI Design Specification

## Overview
This document defines the unified UI design patterns for Just Spent across iOS and Android platforms, ensuring consistent user experience while respecting platform conventions.

## 🎨 Design Philosophy

### Core Principles
- **Voice-First**: Voice recording is the primary interaction method
- **Minimal Friction**: 3-tap maximum for manual operations
- **Consistent Formatting**: All currency amounts use standardized formatting (1,234.56)
- **Adaptive UI**: Interface adapts to data state (empty, single currency, multiple currencies)
- **Material Design 3** (Android) / **Human Interface Guidelines** (iOS)

## 📐 Screen Architecture

### 1. Conditional Screen System

**Three UI States:**
```
Empty State → ExpenseListWithVoiceScreen
Single Currency → SingleCurrencyScreen (no tabs)
Multiple Currencies → MultiCurrencyTabbedScreen (with tabs)
```

**State Transitions:**
```
First Launch
    ↓
Onboarding (currency selection)
    ↓
Empty State (no expenses)
    ↓ (user logs first expense)
    ↓
Single Currency Screen
    ↓ (user logs expense in different currency)
    ↓
Multi-Currency Tabbed Screen
```

### 2. Empty State Design

**Visual Hierarchy:**
```
┌─────────────────────────────────────────────────────┐
│  Gradient Background (Blue → Purple, subtle)        │
│  ┌──────────────────────────────────────────────┐   │
│  │  HEADER CARD (elevated, semi-transparent)    │   │
│  │  ┌─────────────────────┬─────────────────┐   │   │
│  │  │ "Just Spent"        │  TOTAL CARD     │   │   │
│  │  │ subtitle text       │  "Total"        │   │   │
│  │  │ (with mic icon if   │  $0.00          │   │   │
│  │  │  no permission)     │  (green bg)     │   │   │
│  │  └─────────────────────┴─────────────────┘   │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  EMPTY STATE                                 │   │
│  │  🛒 Icon (64dp, faded)                       │   │
│  │  "No Expenses Yet"                           │   │
│  │  "Tap microphone to add expense"             │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│                                            ┌──────┐  │
│                                            │  🎤  │  │
│                                            │ FAB  │  │
│                                            └──────┘  │
└─────────────────────────────────────────────────────┘
```

**Design Specifications:**

**Header Card:**
- Elevation: 8dp
- Border Radius: 16dp (default Material 3)
- Background: Surface color with 90% opacity
- Padding: 20dp all sides
- Margin: 16dp all sides

**Title Section (Left):**
- Primary Text: "Just Spent"
  - Style: `headlineMedium` (Material 3)
  - Weight: Bold
  - Color: `onSurface`
- Subtitle: "Voice-enabled expense tracker"
  - Style: `bodySmall`
  - Color: `onSurface` with 70% opacity
- Permission Icon: Red mic icon (16dp) when no permission
  - Positioned inline with subtitle
  - Tint: `error` color

**Total Card (Right):**
- Background: Green (#4CAF50) with 20% opacity
- Border Radius: 16dp (default)
- Padding: Horizontal 16dp, Vertical 12dp
- Alignment: Right-aligned within container
- Label Text: "Total"
  - Style: `bodySmall`
  - Color: `onSurface` with 70% opacity
  - Alignment: Right
- Amount Text: Formatted total (e.g., "$1,234.56")
  - Style: `titleMedium`
  - Weight: SemiBold
  - Color: `onSurface`
  - Alignment: Right

**Empty State:**
- Icon: Shopping cart (64dp)
  - Tint: `onSurfaceVariant` with 50% opacity
- Title: "No Expenses Yet"
  - Style: `titleMedium`
  - Color: `onSurfaceVariant`
- Subtitle: "Tap the microphone button to add an expense"
  - Style: `bodyMedium`
  - Color: `onSurfaceVariant` with 70% opacity
- Spacing: 16dp between elements
- Alignment: Center vertically and horizontally

**Floating Action Button:**
- Size: 60dp (default), 66dp (recording)
- Position: Bottom-right, 16dp margin
- Colors:
  - Default: `primary` color
  - Recording: `error` color
- Icon: Microphone (24dp)
- Animation: Pulsing scale (1.0 → 1.1) when recording
- Elevation: 6dp (default Material 3 FAB)

**Recording Indicator Card:**
- Appears above FAB when recording
- Background: Surface with 90% opacity
- Border Radius: 20dp
- Padding: Horizontal 12dp, Vertical 8dp
- Elevation: 4dp
- Content:
  - Pulsing dot (8dp circle): Red (listening) / Green (processing)
  - Status text: "Listening..." / "Processing..."
  - Spacing: 8dp between dot and text
  - Style: `bodySmall`

**Gradient Background:**
- Direction: Vertical (top to bottom)
- Start Color: Blue (#1976D2) with 10% opacity
- End Color: Purple (#9C27B0) with 5% opacity

### 3. Single Currency Screen

**Visual Hierarchy:**
```
┌─────────────────────────────────────────────────────┐
│  Gradient Background (Blue → Purple)                │
│  ┌──────────────────────────────────────────────┐   │
│  │  HEADER CARD                                 │   │
│  │  ┌─────────────────────┬─────────────────┐   │   │
│  │  │ "Just Spent"        │  TOTAL CARD     │   │   │
│  │  │ subtitle            │  "Total"        │   │   │
│  │  │                     │  AED 1,234.56   │   │   │
│  │  └─────────────────────┴─────────────────┘   │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  EXPENSE LIST                                │   │
│  │  ┌──────────────────────────────────────┐    │   │
│  │  │  Grocery          AED 150.00         │    │   │
│  │  │  Carrefour        📅 1/15/2025  🎤  │    │   │
│  │  └──────────────────────────────────────┘    │   │
│  │  ┌──────────────────────────────────────┐    │   │
│  │  │  Food & Dining    AED 50.00          │    │   │
│  │  │  Starbucks        📅 1/14/2025       │    │   │
│  │  └──────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────┘   │
│                                            ┌──────┐  │
│                                            │  🎤  │  │
│                                            │ FAB  │  │
│                                            └──────┘  │
└─────────────────────────────────────────────────────┘
```

**Design Specifications:**

**Header Card:** Same as Empty State

**Total Display:**
- Updates dynamically as expenses are added/edited/deleted
- Shows currency symbol + formatted amount
- Uses `CurrencyFormatter` for consistent formatting
- Example: "AED 1,234.56", "$1,234.56", "€1,234.56"

**Expense List:**
- Padding: Horizontal 16dp
- Vertical spacing: 8dp between items

**Expense Row Card:**
- Elevation: 4dp
- Border Radius: 16dp
- Background: Surface with 90% opacity
- Padding: 16dp all sides
- Clickable: Yes (for future detail view)
- Swipeable: Yes (swipe to delete with confirmation)

**Expense Row Layout:**
- Top Row:
  - Left: Category name (`titleMedium`, Medium weight)
  - Right: Amount (`titleMedium`, SemiBold weight)
- Second Row (if merchant exists):
  - Merchant name (`bodyMedium`, 70% opacity)
  - Top margin: 4dp
- Bottom Row:
  - Left side:
    - Date (`bodySmall`, 60% opacity)
    - Voice indicator (mic icon, 12dp, blue) if voice source
    - Spacing: 8dp between date and icon
  - Right side:
    - Delete button (`bodySmall`, error color)

**Voice Indicator:**
- Shows only for voice-sourced expenses
- Icon: Microphone (12dp)
- Tint: Blue (#2196F3)
- Position: After date, 8dp spacing

### 4. Multi-Currency Tabbed Screen

**Visual Hierarchy:**
```
┌─────────────────────────────────────────────────────┐
│  Gradient Background                                │
│  ┌──────────────────────────────────────────────┐   │
│  │  HEADER CARD                                 │   │
│  │  ┌─────────────────────┬─────────────────┐   │   │
│  │  │ "Just Spent"        │  TOTAL CARD     │   │   │
│  │  │ subtitle            │  "Total"        │   │   │
│  │  │                     │  AED 2,345.67   │   │   │
│  │  └─────────────────────┴─────────────────┘   │   │
│  └──────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────┐   │
│  │  [AED] [USD] [EUR] [GBP] [INR] [SAR]        │   │
│  │  ─────                    (scrollable tabs)  │   │
│  └──────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────┐   │
│  │  EXPENSE LIST (filtered by selected tab)     │   │
│  │  ┌──────────────────────────────────────┐    │   │
│  │  │  Grocery          AED 150.00         │    │   │
│  │  └──────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────┘   │
│                                            ┌──────┐  │
│                                            │  🎤  │  │
│                                            └──────┘  │
└─────────────────────────────────────────────────────┘
```

**Design Specifications:**

**Header Card:** Same as Single Currency, but total updates when tab changes

**Currency Tab Bar:**
- Component: `ScrollableTabRow` (Material 3)
- Background: Surface color
- Elevation: Tonal 3dp, Shadow 2dp
- Edge Padding: 0dp (full width)
- Tab Indicator:
  - Color: Primary
  - Height: 3dp
  - Style: Bottom line

**Individual Tab:**
- Padding: Vertical 12dp, Horizontal 12dp
- Spacing between tabs: 8dp
- Content Layout: Horizontal row with 6dp spacing
- Selected State:
  - Text Color: Primary
  - Symbol Weight: Bold
  - Code Weight: SemiBold
- Unselected State:
  - Text Color: OnSurface
  - Symbol Weight: Medium
  - Code Weight: Normal

**Tab Content:**
- Currency Symbol: `titleMedium` (e.g., "$", "€", "د.إ")
- Currency Code: `bodyMedium` (e.g., "USD", "EUR", "AED")
- Both update styling on selection

**Dynamic Tab Behavior:**
- Tabs generated from distinct currencies in database
- Sorted alphabetically by display name
- Default tab: User's selected default currency
- Tab order persists during session
- New tab appears when first expense in new currency is added

**Expense List (Per Tab):**
- Filtered by selected currency
- Same design as Single Currency Screen
- Uses shared `CurrencyExpenseListScreen` component
- Shows empty state if no expenses for that currency
- Reuses expense row card design

**Empty State (Per Currency):**
```
┌──────────────────────────────────────────────┐
│  🛒 Icon (64dp, faded)                       │
│  "No AED Expenses"                           │
│  "Tap the microphone button to add expense"  │
└──────────────────────────────────────────────┘
```
- Title includes currency display name
- Otherwise identical to main empty state

## 🎨 Design Tokens

### Colors

**Material 3 Color System:**
```yaml
primary: "#1976D2"           # Blue
on_primary: "#FFFFFF"        # White
primary_container: "#90CAF9" # Light Blue

secondary: "#9C27B0"         # Purple
on_secondary: "#FFFFFF"      # White

tertiary: "#4CAF50"          # Green (for totals)

error: "#D32F2F"             # Red (recording, errors)
on_error: "#FFFFFF"          # White

surface: "#FFFFFF"           # White
on_surface: "#000000"        # Black
surface_variant: "#F5F5F5"   # Light Gray
on_surface_variant: "#616161" # Medium Gray

background: "#FAFAFA"        # Off-white
on_background: "#000000"     # Black

gradient_start: "#1976D2" (10% opacity)  # Blue
gradient_end: "#9C27B0" (5% opacity)     # Purple
```

**Category Colors:**
```yaml
food_dining: "#FF6B6B"       # Red
grocery: "#4ECDC4"           # Teal
transport: "#45B7D1"         # Blue
shopping: "#96CEB4"          # Green
entertainment: "#FECA57"     # Yellow
bills_utilities: "#48BFE3"  # Light Blue
healthcare: "#74C0FC"        # Sky Blue
education: "#B197FC"         # Purple
other: "#868E96"             # Gray
```

### Typography

**Material 3 Type Scale (Android) / SF Pro (iOS):**
```yaml
headlineMedium:
  size: 28sp / 28pt
  weight: Bold
  line_height: 36sp / 34pt
  letter_spacing: 0

titleMedium:
  size: 16sp / 16pt
  weight: Medium
  line_height: 24sp / 22pt
  letter_spacing: 0.15sp / 0.1pt

bodyMedium:
  size: 14sp / 14pt
  weight: Regular
  line_height: 20sp / 19pt
  letter_spacing: 0.25sp / 0.12pt

bodySmall:
  size: 12sp / 12pt
  weight: Regular
  line_height: 16sp / 16pt
  letter_spacing: 0.4sp / 0.16pt
```

### Spacing

**Material 3 Spacing System:**
```yaml
spacing_xs: 4dp / 4pt
spacing_sm: 8dp / 8pt
spacing_md: 12dp / 12pt
spacing_lg: 16dp / 16pt
spacing_xl: 20dp / 20pt
spacing_xxl: 24dp / 24pt
spacing_xxxl: 32dp / 32pt
```

### Elevation

**Material 3 Elevation System:**
```yaml
elevation_0: 0dp (flat)
elevation_1: 1dp (lowest)
elevation_2: 3dp (low)
elevation_3: 6dp (medium)
elevation_4: 8dp (high)
elevation_5: 12dp (highest)
```

**Shadow Values:**
```yaml
card_elevation: 4dp
header_elevation: 8dp
fab_elevation: 6dp
tab_bar_elevation_tonal: 3dp
tab_bar_elevation_shadow: 2dp
```

### Border Radius

**Material 3 Shape System:**
```yaml
shape_xs: 4dp / 4pt
shape_sm: 8dp / 8pt
shape_md: 12dp / 12pt
shape_lg: 16dp / 16pt
shape_xl: 20dp / 20pt
shape_full: 50% (circular)
```

**Component Radii:**
```yaml
card: 16dp (default Material 3)
button: 20dp (recording indicator)
fab: 50% (circular)
```

### Icons

**Icon Sizes:**
```yaml
icon_xs: 12dp / 12pt (voice indicator)
icon_sm: 16dp / 16pt (permission warning)
icon_md: 24dp / 24pt (FAB, navigation)
icon_lg: 48dp / 48pt (category icons)
icon_xl: 64dp / 64pt (empty state)
```

**Icon Library:**
- Android: Material Icons
- iOS: SF Symbols

## 🔄 Animations

### Voice Recording Animation

**Pulsing Scale Animation:**
```kotlin
// Android (Compose)
val infiniteTransition = rememberInfiniteTransition()
val scale by infiniteTransition.animateFloat(
    initialValue = 1f,
    targetValue = 1.1f,
    animationSpec = infiniteRepeatable(
        animation = tween(500, easing = EaseInOut),
        repeatMode = RepeatMode.Reverse
    )
)
```

**Applied To:**
- FAB size (60dp → 66dp)
- Recording indicator dot (8dp with scale 1.0 → 1.1)

**Duration:** 500ms per cycle
**Easing:** EaseInOut
**Repeat Mode:** Reverse (ping-pong)

### Tab Switching Animation

**Indicator Slide:**
- Duration: 250ms
- Easing: Fast-out-slow-in
- Style: Slide along bottom with smooth transition

### List Item Animation

**Swipe to Delete:**
- Direction: Left or Right
- Distance Threshold: 50% of card width
- Background Color: Error container
- Text: "Delete" (OnErrorContainer color)
- Alignment: Opposite to swipe direction

## 📏 Responsive Design

### Breakpoints

**Android:**
```yaml
compact: 0-599dp (phones)
medium: 600-839dp (large phones, small tablets)
expanded: 840dp+ (tablets)
```

**iOS:**
```yaml
compact_width: iPhone portrait
regular_width: iPhone landscape, iPad
compact_height: iPhone landscape
regular_height: iPhone portrait, iPad
```

### Adaptive Layouts

**Compact (Phone):**
- Single column layout
- Full-width cards
- FAB bottom-right
- Scrollable tabs (horizontal)

**Medium (Tablet):**
- Single column with wider cards (max-width: 600dp)
- FAB bottom-right with increased margin
- Tabs can show all if ≤6 currencies

**Expanded (Large Tablet):**
- Two-column layout (list + detail view)
- Master-detail pattern
- FAB in detail pane

## 💱 Currency Formatting

### Standardized Format

**All Currencies Use:**
- Decimal Separator: `.` (point)
- Grouping Separator: `,` (comma)
- Decimal Places: 2 (fixed)
- Grouping: Yes (thousands)

**Examples:**
```
AED 1,234.56
$1,234.56
€1,234.56
£1,234.56
₹1,234.56
﷼1,234.56
```

**Format Pattern:**
```
[Symbol] [Grouped Integer].[Decimal]
OR
[Grouped Integer].[Decimal] [Symbol]  (based on locale convention)
```

**Implementation:**
- Use `CurrencyFormatter` utility on all platforms
- Symbol position respects locale (before/after)
- Always show symbol in totals
- Always show 2 decimal places (even .00)

### Currency Formatter

**Android (Implemented):**
```kotlin
object CurrencyFormatter {
    fun format(
        amount: BigDecimal,
        currency: Currency,
        showSymbol: Boolean = true,
        showCode: Boolean = false
    ): String {
        val formatter = createFormatter(currency)
        val formatted = formatter.format(amount)

        return when {
            showSymbol && showCode -> "${currency.symbol} $formatted ${currency.code}"
            showSymbol -> "${currency.symbol} $formatted"
            showCode -> "$formatted ${currency.code}"
            else -> formatted
        }
    }

    private fun createFormatter(currency: Currency): DecimalFormat {
        val symbols = DecimalFormatSymbols(Locale.US).apply {
            decimalSeparator = '.'
            groupingSeparator = ','
        }

        return DecimalFormat().apply {
            decimalFormatSymbols = symbols
            minimumFractionDigits = 2
            maximumFractionDigits = 2
            isGroupingUsed = true
            roundingMode = RoundingMode.HALF_UP
        }
    }
}
```

**iOS (To Be Implemented):**
```swift
struct CurrencyFormatter {
    static func format(
        amount: Decimal,
        currency: Currency,
        showSymbol: Bool = true,
        showCode: Bool = false
    ) -> String {
        let formatter = createFormatter(for: currency)
        let formatted = formatter.string(from: amount as NSDecimalNumber) ?? "0.00"

        if showSymbol && showCode {
            return "\(currency.symbol) \(formatted) \(currency.code)"
        } else if showSymbol {
            return "\(currency.symbol) \(formatted)"
        } else if showCode {
            return "\(formatted) \(currency.code)"
        } else {
            return formatted
        }
    }

    private static func createFormatter(for currency: Currency) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.roundingMode = .halfUp
        return formatter
    }
}
```

## ♿ Accessibility

### Screen Reader Support

**Content Descriptions:**
```yaml
header_title: "Just Spent, voice-enabled expense tracker"
total_card: "Total spending: [formatted amount]"
currency_tab: "[Currency name], [selected/not selected]"
expense_row: "[Category], [amount], [merchant if present], [date], [voice input if applicable]"
fab_default: "Record expense with voice"
fab_recording: "Recording in progress, tap to stop"
recording_indicator: "[Listening/Processing], [detected speech indicator]"
empty_state: "No expenses yet, tap microphone button to add first expense"
```

**VoiceOver/TalkBack Navigation:**
- Header card: Single focus group
- Tab bar: Swipe through each tab individually
- Expense list: Each card is focusable
- FAB: Always accessible, announces state changes

### Contrast Ratios

**WCAG 2.1 AA Compliance:**
```yaml
normal_text: 4.5:1 minimum
large_text: 3:1 minimum (18pt+ or 14pt+ bold)
interactive_elements: 3:1 minimum
```

**Verified Combinations:**
- Primary text on Surface: 21:1 ✓
- Secondary text (70% opacity) on Surface: 4.6:1 ✓
- Primary button text: 4.5:1 ✓
- Error text: 4.8:1 ✓

### Touch Targets

**Minimum Sizes:**
```yaml
android: 48dp × 48dp (Material 3)
ios: 44pt × 44pt (HIG)
```

**Applied To:**
- FAB: 60dp/pt (exceeds minimum)
- Tabs: 48dp/pt height minimum
- Delete button: 44dp/pt minimum
- Swipe gesture: Full card height

### Dynamic Type Support

**Text Scaling:**
- Support system font size preferences
- Test at 200% scale
- Ensure layout doesn't break
- Truncate with ellipsis if needed

## 🌐 Localization

### RTL (Right-to-Left) Support

**Affected Currencies:**
- AED (Arabic - UAE)
- SAR (Arabic - Saudi Arabia)

**Layout Mirroring:**
- Text alignment: Reverse for RTL
- Icon positions: Mirror horizontally
- Tab bar: Reverse order
- Expense row: Amount stays right-aligned

**Text Direction:**
```kotlin
// Android
LocalLayoutDirection.current == LayoutDirection.Rtl

// iOS
UIView.userInterfaceLayoutDirection == .rightToLeft
```

### Number Formatting

**Force Western Numerals:**
- Always use 0-9 (not Arabic-Indic numerals)
- Locale set to `en_US` for number formatting
- Ensures consistency across all languages

## 📱 Platform-Specific Guidelines

### Android (Material 3) - IMPLEMENTED

**Components:**
- `Scaffold` for screen structure
- Custom `Card` for header (replaces TopAppBar)
- `ScrollableTabRow` for currency tabs
- `FloatingActionButton` for voice recording
- `Card` with `onClick` for expense rows
- `SwipeToDismiss` for delete gesture
- `LazyColumn` for expense lists

**State Management:**
- `collectAsState()` for Flow observations
- `remember()` for computed values
- `mutableStateOf()` for UI state
- `@HiltViewModel` for dependency injection

**Implementation Status:**
- ✅ Empty state (ExpenseListWithVoiceScreen)
- ✅ Single currency (SingleCurrencyScreen)
- ✅ Multi-currency tabs (MultiCurrencyTabbedScreen)
- ✅ Header card with dynamic total
- ✅ Gradient background
- ✅ Custom FAB with recording indicator
- ✅ Currency formatter
- ✅ Expense row design
- ✅ Voice indicator
- ✅ Swipe to delete

### iOS (SwiftUI) - PENDING

**Components (To Be Implemented):**
- `VStack`/`HStack` for layout
- Custom header card (match Android design)
- `TabView` with page style for currencies
- Custom floating button (match Android FAB)
- `List` or `ScrollView` + `LazyVStack` for expenses
- `.swipeActions` for delete gesture

**State Management:**
- `@State` for local UI state
- `@ObservedObject` for ViewModel
- `@FetchRequest` for Core Data
- Combine for reactive updates

**Implementation Checklist:**
- ⏳ Empty state design (match Android)
- ⏳ Single currency screen (match Android)
- ⏳ Multi-currency tabbed screen (match Android)
- ⏳ Header card implementation
- ⏳ Gradient background
- ⏳ Custom FAB equivalent
- ⏳ Currency formatter implementation
- ⏳ Expense row design
- ⏳ Voice indicator icon
- ⏳ Swipe to delete
- ⏳ Empty state per currency

## 🔧 Key Implementation Notes

### Dynamic Total Calculation

**IMPORTANT:** Total is calculated and displayed in the header card, NOT per-tab.

**Single Currency Screen:**
```kotlin
// Calculate total for the single currency
val currencyTotal = remember(expenses, currency) {
    expenses
        .filter { it.currency == currency.code }
        .fold(BigDecimal.ZERO) { acc, expense -> acc.add(expense.amount) }
}

val formattedTotal = remember(currencyTotal, currency) {
    CurrencyFormatter.format(
        amount = currencyTotal,
        currency = currency,
        showSymbol = true,
        showCode = false
    )
}
```

**Multi-Currency Tabbed Screen:**
```kotlin
// Calculate total for selected tab
val selectedCurrencyTotal = remember(expenses, selectedCurrency) {
    expenses
        .filter { it.currency == selectedCurrency.code }
        .fold(BigDecimal.ZERO) { acc, expense -> acc.add(expense.amount) }
}

val formattedTotal = remember(selectedCurrencyTotal, selectedCurrency) {
    CurrencyFormatter.format(
        amount = selectedCurrencyTotal,
        currency = selectedCurrency,
        showSymbol = true,
        showCode = false
    )
}
```

**Result:**
- Total updates dynamically when switching tabs
- Currency symbol updates with selected currency
- Uses standardized formatting (1,234.56)

### Shared Components

**CurrencyExpenseListScreen:**
- Reusable component for expense lists
- Used by both SingleCurrencyScreen and MultiCurrencyTabbedScreen
- Filters expenses by currency
- Shows per-currency empty state
- Does NOT display total (handled by parent)

---

*This UI specification ensures consistent, accessible, and beautiful design across iOS and Android platforms. Android implementation is complete and serves as reference for iOS development.*
