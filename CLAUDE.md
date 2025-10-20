# Just Spent - Claude Code Memory

@just-spent-master-plan.md
@data-models-spec.md

## 🎯 Current Context

**Status**: Documentation → Implementation transition  
**Phase**: Foundation (Week 1-2)  
**Priority**: iOS Xcode project + Core Data setup  
**Developer**: Solo, iOS expertise, Android learning

## 🏗️ Architecture Quick Reference

### Tech Stack
- **iOS**: Swift 5.7+, SwiftUI, MVVM, Core Data, SiriKit
- **Android**: Kotlin 1.8+, Jetpack Compose, MVVM, Room, App Actions
- **Strategy**: Local-first, offline-capable, voice-optimized

### Core Standards
- SOLID principles mandatory
- 80%+ test coverage
- Clean Architecture: Presentation → Domain → Data
- Comprehensive error handling
- Voice processing <1.5s target

## 🎤 Voice Integration Essentials

@ios-siri-integration.md
@android-assistant-integration.md

### Primary Voice Patterns
1. `"I just spent [amount] [currency] on [category]"`
2. `"I spent [amount] at [merchant]"`
3. `"Log [amount] for [category]"`

### Processing Pipeline
Voice → Intent Classification → Entity Extraction → Validation → Storage → Confirmation

## 📊 Data Layer (Core Models)

Reference: @data-models-spec.md for complete schemas

### Expense Entity (Simplified)
```swift
// iOS Core Data essentials
id: UUID, amount: NSDecimalNumber, currency: String
category: String, merchant: String?, transactionDate: Date
source: String, voiceTranscript: String?
```

```kotlin
// Android Room essentials  
id: String, amount: BigDecimal, currency: String
category: Category, merchant: String?, transactionDate: LocalDateTime
source: ExpenseSource, voiceTranscript: String?
```

## 🧪 Testing Standards

Reference: @comprehensive-test-plan.md

### Coverage Targets
- Unit Tests: 85% minimum
- Voice Integration: All patterns tested
- Performance: <1.5s voice processing
- Security: OWASP Mobile Top 10 compliance

## 🚀 Current Sprint Tasks

### Multi-Currency Tabbed UI Implementation
1. ✅ Currency onboarding screens (iOS & Android)
2. ✅ Onboarding completion flags in UserPreferences
3. 🔄 **IN PROGRESS**: Onboarding navigation logic on app launch
4. ⏳ Currency tab bar component (iOS & Android)
5. ⏳ Dynamic tab generation based on expenses
6. ⏳ Per-currency expense filtering
7. ⏳ Per-tab total calculation
8. ⏳ Tab view integration into ContentView
9. ⏳ Empty states and edge cases
10. ⏳ Complete tabbed currency flow testing

### Code Generation Requests
When asking Claude Code:
- "Implement onboarding navigation in JustSpentApp.swift on launch"
- "Create scrollable currency tab bar for SwiftUI"
- "Build per-currency expense filtering logic"
- "Generate dynamic tab creation based on expense currencies"
- "Create currency-specific total calculation views"

## 🔧 Development Patterns

### File Organization
```
ios/JustSpent/
├── Models/      # Core Data models
├── Views/       # SwiftUI views  
├── ViewModels/  # Business logic
├── Services/    # Data/voice services
└── SiriIntents/ # Voice integration
```

### Error Handling Pattern
```swift
enum ExpenseError: LocalizedError {
    case invalidAmount(String)
    case categoryNotFound(String)
    case voiceParsingFailed(String)
}
```

### Naming Conventions
- PascalCase for types, camelCase for variables
- Descriptive names: `ExpenseRepository`, `VoiceCommandParser`
- Tests: `ExpenseRepositoryTest`, `testAddExpenseSuccess()`

## ⚡ Performance Constraints

### iOS SiriKit Limits
- Memory: <30MB for intent extension
- Processing: <10s before timeout
- Always implement proper cleanup

### Voice Processing Targets
- Intent recognition: <1.5s
- Database write: <100ms
- UI update: <16ms (60fps)

## 🔒 Security Essentials

- Encrypt financial data at rest
- Sanitize voice input before processing
- Never log sensitive data in production
- Validate all user inputs
- Voice transcript retention: 7 days max

## 💱 Multi-Currency Architecture

### Conditional UI Design
- **Single Currency → Single List** (no tabs when only one currency exists)
- **Multiple Currencies → Tabbed Interface** (tabs appear when 2+ currencies exist)
- **Universal Currency Support** - Any ISO 4217 currency via voice (not limited to 6)
- **Predefined + Dynamic** - 6 common currencies (AED, USD, EUR, GBP, INR, SAR) + any additional detected
- **Dynamic tab creation** when new currency detected from voice
- **Same UI per currency**: expense list + total at top

### Currency Flow
1. **First Launch**: Onboarding → Request Permissions → Select Default Currency
2. **Single Currency**: Show simple list (no tabs)
3. **Multiple Currencies**: Show tabbed interface with currency switcher
4. **Voice Detection**: Auto-detect currency from voice ("50 dirhams" → AED)
5. **Universal Support**: Detect ANY currency ("100 kuna" → create HRK tab)
6. **Fallback**: Use default currency if none specified in voice

### Onboarding Requirements
- **Step 1: Welcome** - App introduction
- **Step 2: Permissions** - Siri/Assistant, Microphone (required), Notifications (optional)
- **Step 3: Currency Selection** - Choose from 6 predefined currencies
- **Must complete** before main app access
- Save to UserPreferences/DataStore with `hasCompletedOnboarding` flag

## 📱 UI/UX Principles

- Voice-first design philosophy
- Multi-currency tabbed interface
- Currency-specific expense isolation
- 3-tap max for manual operations
- Instant confirmation for voice commands
- Accessibility (VoiceOver) from day 1
- Onboarding-first user experience

## 🎯 Success Metrics

**This Week**: Voice-log a test expense successfully  
**Quality Gates**: All tests pass, no security issues  
**Performance**: Voice processing under target times

---

*Smart references to comprehensive docs, focused working context for development*