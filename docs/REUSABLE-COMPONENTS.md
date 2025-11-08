# Just Spent - Reusable Components Guide

## Overview

This document catalogs all reusable UI components in the Just Spent app, ensuring consistency across iOS and Android platforms. All components follow the design specifications from `ui-design-spec.md` and are tested following TDD principles.

## Table of Contents

1. [Button Components](#button-components)
2. [Card Components](#card-components)
3. [Empty State Components](#empty-state-components)
4. [List Components](#list-components)
5. [Usage Guidelines](#usage-guidelines)

---

## Button Components

### PrimaryButton

**Purpose:** Standard primary action button with consistent styling across iOS and Android.

**Design Specifications:**
- **Height:** 56dp/pt (optimal touch target)
- **Corner Radius:** 12dp/pt
- **Background:** Primary blue color
- **Text:** White, headline/titleMedium font, SemiBold weight
- **Layout:** Full width
- **States:** Enabled, Disabled (with opacity)

**Files:**
- iOS: `ios/JustSpent/JustSpent/Views/Components/PrimaryButton.swift`
- Android: `android/app/src/main/java/com/justspent/app/ui/components/PrimaryButton.kt`

**Tests:**
- iOS UI Tests: `ios/JustSpent/JustSpentUITests/OnboardingFlowUITests.swift`
  - `testOnboardingContinueButtonHasStandardHeight()` - Verifies 56pt height
- Android UI Tests: `android/app/src/androidTest/kotlin/com/justspent/app/OnboardingFlowUITest.kt`
  - `onboarding_continueButtonIsProperlyPositioned()` - Verifies 56dp height

**Note:** Component behavior is tested through UI tests in screens that use it, ensuring real-world usage validation.

**Usage:**

**iOS:**
```swift
PrimaryButton(
    text: "Continue",
    action: {
        // Your action here
    },
    enabled: true, // Optional, defaults to true
    accessibilityIdentifier: "continue_button" // Optional
)
.padding(.horizontal, 24)
```

**Android:**
```kotlin
PrimaryButton(
    text = "Continue",
    onClick = {
        // Your action here
    },
    enabled = true, // Optional, defaults to true
    testTag = "continue_button" // Optional
)
```

**When to Use:**
- Primary actions (Continue, Submit, Save, etc.)
- Confirmation buttons
- CTA buttons

**When NOT to Use:**
- Secondary actions (use SecondaryButton - to be created)
- Tertiary actions (use TextButton - to be created)
- Navigation (use NavigationLink/NavController)

---

## Card Components

### AppHeaderCard

**Purpose:** Display app title and total spending amount in header.

**Design Specifications:**
- **Elevation:** 8dp (iOS shadow equivalent)
- **Border Radius:** 16dp
- **Background:** Surface color with 90% opacity
- **Padding:** 20dp all sides
- **Layout:** HStack with title (left) and total (right)

**Files:**
- iOS: `ios/JustSpent/JustSpent/Views/Components/AppHeaderCard.swift`
- Android: To be created

**Usage:**

**iOS:**
```swift
AppHeaderCard(
    title: "Just Spent",
    subtitle: "Voice-enabled expense tracker",
    total: formattedTotal,
    currency: selectedCurrency
)
```

**When to Use:**
- Main screen header
- Summary screens
- Dashboard displays

---

## Empty State Components

### EmptyStateView

**Purpose:** Display when no data is available (no expenses, no results, etc.)

**Design Specifications:**
- **Icon Size:** 64dp
- **Icon Color:** OnSurfaceVariant with 50% opacity
- **Title:** titleMedium, OnSurfaceVariant
- **Subtitle:** bodyMedium, OnSurfaceVariant with 70% opacity
- **Spacing:** 16dp between elements
- **Alignment:** Center (vertical and horizontal)

**Files:**
- iOS: `ios/JustSpent/JustSpent/Views/Components/EmptyStateView.swift`
- Android: Inline in screens (to be extracted)

**Usage:**

**iOS:**
```swift
EmptyStateView(
    icon: "cart.fill",
    title: "No Expenses Yet",
    subtitle: "Tap the microphone button to add an expense",
    accessibilityIdentifier: "empty_state"
)
```

**When to Use:**
- Empty expense lists
- No search results
- Empty categories
- First-time user screens

---

## List Components

### ExpenseRowView

**Purpose:** Display individual expense item in a list.

**Design Specifications:**
- **Elevation:** 4dp
- **Border Radius:** 16dp
- **Background:** Surface with 90% opacity
- **Padding:** 16dp all sides
- **Layout:** Category/Amount (top), Merchant (middle), Date/Voice indicator (bottom)

**Files:**
- iOS: `ios/JustSpent/JustSpent/Views/Components/ExpenseRowView.swift`
- Android: Inline in screens (to be extracted)

**Usage:**

**iOS:**
```swift
ExpenseRowView(
    expense: expense,
    currency: selectedCurrency,
    onDelete: {
        // Delete action
    }
)
```

**When to Use:**
- Expense list displays
- Search results
- Category-filtered lists

---

## Usage Guidelines

### Component Selection Criteria

**1. Consistency First**
- Always use existing components when available
- Don't create inline buttons/cards if reusable component exists
- Maintain cross-platform consistency (iOS and Android should look similar)

**2. When to Create New Component**
- Used in 3+ places
- Complex UI with specific styling requirements
- Needs consistent behavior across screens

**3. Component Creation Checklist**
- [ ] Create iOS version (`Views/Components/`)
- [ ] Create Android version (`ui/components/`)
- [ ] Write unit tests (both platforms)
- [ ] Add to this documentation
- [ ] Update CLAUDE.md if widely used
- [ ] Add preview/example usage

### Naming Conventions

**iOS:**
- File: `ComponentName.swift` (PascalCase)
- Struct: `ComponentName` (PascalCase)
- Location: `ios/JustSpent/JustSpent/Views/Components/`

**Android:**
- File: `ComponentName.kt` (PascalCase)
- Function: `ComponentName` (PascalCase with @Composable)
- Location: `android/app/src/main/java/com/justspent/app/ui/components/`

### Testing Requirements

**All components MUST have:**
- Unit tests (behavior, props, actions)
- UI tests for visual verification (if applicable)
- Accessibility tests (VoiceOver/TalkBack compatibility)

**Test files:**
- iOS: `ios/JustSpent/JustSpentTests/ComponentNameTests.swift`
- Android: `android/app/src/test/java/com/justspent/app/ui/components/ComponentNameTest.kt`

---

## Future Components (Planned)

### Buttons
- [ ] **SecondaryButton** - Outlined style for secondary actions
- [ ] **TextButton** - Text-only for tertiary actions
- [ ] **IconButton** - Icon-only for toolbar actions

### Cards
- [ ] **ExpenseCard** - Standalone expense display card
- [ ] **SummaryCard** - Statistics/summary display
- [ ] **CategoryCard** - Category selection/display

### Input
- [ ] **CurrencyInput** - Amount input with currency selector
- [ ] **CategorySelector** - Category picker component
- [ ] **DatePicker** - Date selection component

### Indicators
- [ ] **LoadingIndicator** - Consistent loading spinner
- [ ] **VoiceRecordingIndicator** - Voice recording status
- [ ] **ProgressBar** - Budget/goal progress

---

## Component Maintenance

### Updating Components

**When modifying existing components:**
1. Update both iOS and Android versions
2. Run all tests to ensure no breaking changes
3. Update this documentation
4. Update examples if API changes
5. Consider backward compatibility

### Deprecating Components

**If a component is no longer needed:**
1. Mark as `@Deprecated` with migration guide
2. Remove from this documentation (move to "Deprecated" section)
3. Update CLAUDE.md
4. Create migration timeline (2-3 sprints)
5. Remove after migration complete

---

## Quick Reference

### Component Import Paths

**iOS:**
```swift
// Components are in same module, no import needed
// Just use: PrimaryButton(...)
```

**Android:**
```kotlin
import com.justspent.app.ui.components.PrimaryButton
```

### Common Patterns

**Button with padding:**
```swift
// iOS
PrimaryButton(text: "Continue", action: {})
    .padding(.horizontal, 24)
    .padding(.bottom, 32)
```

```kotlin
// Android - padding applied externally
Column(modifier = Modifier.padding(horizontal = 24.dp)) {
    PrimaryButton(text = "Continue", onClick = {})
    Spacer(modifier = Modifier.height(32.dp))
}
```

---

## Related Documentation

- **Design Specs:** `ui-design-spec.md` - Complete UI/UX specifications
- **Testing Guide:** `TESTING-GUIDE.md` - Testing standards and practices
- **Code Style:** `CLAUDE.md` - Development standards and conventions
- **Git Workflow:** `docs/GIT-WORKFLOW-RULES.md` - Commit and branch guidelines

---

**Last Updated:** 2025-11-08
**Maintained By:** Development Team
**Related Issues:** #components-consistency

**Note:** This is a living document. Update it whenever you add, modify, or deprecate components.
