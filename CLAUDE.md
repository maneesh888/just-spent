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

### This Week Priority
- [ ] Initialize iOS Xcode project with Core Data
- [ ] Create basic Expense entity
- [ ] Implement CRUD repository pattern
- [ ] Build simple SwiftUI expense list

### Code Generation Requests
When asking Claude Code:
- "Generate iOS Core Data Expense model with voice transcript field"
- "Create MVVM expense repository with error handling"
- "Build SwiftUI expense list with navigation"
- "Generate comprehensive unit tests for expense model"

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

## 📱 UI/UX Principles

- Voice-first design philosophy
- 3-tap max for manual operations
- Instant confirmation for voice commands
- Accessibility (VoiceOver) from day 1

## 🎯 Success Metrics

**This Week**: Voice-log a test expense successfully  
**Quality Gates**: All tests pass, no security issues  
**Performance**: Voice processing under target times

---

*Smart references to comprehensive docs, focused working context for development*