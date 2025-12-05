# Just Spent - Claude Code Memory

@just-spent-master-plan.md
@data-models-spec.md
@TESTING-GUIDE.md
@docs/GIT-WORKFLOW-RULES.md
@docs/REUSABLE-COMPONENTS.md
@docs/DEPLOYMENT-README.md
@KNOWN_ISSUES.md

## 🎯 Current Context

**Status**: Core UI Complete (iOS & Android) → Voice Integration Phase
**Phase**: Phase 3 (Week 5-6) - Voice Integration & Testing (95% complete)
**Priority**: Siri & Google Assistant integration for voice-activated expense logging
**Developer**: Solo, iOS expertise, Android learning
**Deployment**: Fully automated CI/CD pipeline ready (TestFlight & Play Store)

**Recent Completion:**
- ✅ **Complete CI/CD Pipeline** - Fully automated iOS and Android deployment
- ✅ Android multi-currency tabbed UI fully implemented
- ✅ iOS multi-currency UI with custom header
- ✅ Dynamic total calculation per currency
- ✅ Consistent currency formatting (. decimal, , grouping)
- ✅ Reusable components library (PrimaryButton, Header, EmptyState)

**Known Issues** (Dec 5, 2025):
- ⚠️ **Android**: 2 UI tests failing on phone emulator (83.3% pass rate) - timing issues in EditExpenseUITest
- ⚠️ **iOS**: 1 UI test failing (98.8% pass rate) - multi-currency tab display issue
- ⚠️ **Overall**: 425/428 tests passing (99.3%) - See @KNOWN_ISSUES.md for details and proposed fixes

**Reference Documents:**
- @ui-design-spec.md - Complete UI implementation details (multi-currency, design tokens, components)
- @data-models-spec.md - Complete data schemas and multi-currency architecture
- @docs/REUSABLE-COMPONENTS.md - UI component catalog and usage guide
- @KNOWN_ISSUES.md - Current test failures and known issues tracker
- @android/TEST_STATUS_FINAL.md - Detailed Android test analysis
- @ios/TEST_STATUS_FINAL.md - Detailed iOS test analysis

## 🏗️ Architecture Quick Reference

### Tech Stack
- **iOS**: Swift 5.7+, SwiftUI, MVVM, Core Data, SiriKit
- **Android**: Kotlin 1.8+, Jetpack Compose, MVVM, Room, App Actions
- **Strategy**: Local-first, offline-capable, voice-optimized

### Core Standards
- **TEST DRIVEN DEVELOPMENT (TDD) MANDATORY** - Write tests BEFORE implementation
- SOLID principles mandatory
- 80%+ test coverage
- Clean Architecture: Presentation → Domain → Data
- Comprehensive error handling
- Voice processing <1.5s target

## ⚠️ TEST DRIVEN DEVELOPMENT (TDD) - MANDATORY

**CRITICAL RULE**: ALL code changes MUST follow TDD workflow. NO EXCEPTIONS.

### TDD Workflow (Red-Green-Refactor)

**ALWAYS follow this sequence:**

1. **🔴 RED**: Write a failing test first
2. **🟢 GREEN**: Write minimal code to pass the test
3. **♻️ REFACTOR**: Clean up the code

### TDD Rules for This Project

- ✅ **Test first, code second** - No exceptions
- ✅ **One test at a time** - Focus on one behavior per test
- ✅ **Run tests frequently** - After every small change
- ✅ **Commit only when green** - All tests must pass before commit
- ❌ **Never write production code without a failing test**
- ❌ **Never commit failing tests** (except in WIP branches with --no-verify)

**For detailed TDD examples and patterns**, see @TESTING-GUIDE.md

**For git workflow with TDD**, see @docs/GIT-WORKFLOW-RULES.md

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

**Reference**: @data-models-spec.md for complete schemas and multi-currency architecture

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

**Reference**: @TESTING-GUIDE.md for complete testing guide

**⚠️ CRITICAL**: All tests must be written BEFORE implementation (TDD mandatory)

### Coverage Targets
- Unit Tests: 85% minimum
- Voice Integration: All patterns tested
- Performance: <1.5s voice processing
- Security: OWASP Mobile Top 10 compliance

### Running Tests
**iOS:**
```bash
cd ios/JustSpent
xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Android:**
```bash
cd android
./test.sh unit    # Unit tests only
./test.sh ui      # UI tests (requires emulator)
./test.sh all     # All tests
```

## 🔄 CI/CD - Hybrid Approach

**Reference**: @LOCAL-CI.md for complete documentation

### Quick Start
```bash
# First time setup
./scripts/install-hooks.sh

# Run local CI checks
./local-ci.sh --all          # Full: build + all tests (~5-10 min)
./local-ci.sh --all --quick  # Fast: build + unit tests (~2-3 min)
./local-ci.sh --ios          # iOS only
./local-ci.sh --android      # Android only
```

### Strategy: Hybrid CI/CD

**Local CI** (for development):
- Runs on your Mac for instant feedback
- 3-5x faster than GitHub Actions (5-10 min vs 11-12 min)
- Pre-commit hook prevents breaking changes
- Zero cost, no network dependency

**GitHub Actions** (for production):
- Runs automatically on `main` branch only
- Safety net for production code
- Can be manually triggered for any branch

### Pre-Commit Hook

Automatically enforces TDD practices before each commit:
- ✅ Validates test coverage for all changed files
- ✅ Runs `./local-ci.sh --all --quick` to verify tests pass
- ✅ Blocks commits with failing tests or missing test coverage

**To bypass** (for WIP commits only):
```bash
git commit --no-verify -m "WIP: message"
```

**See @docs/GIT-WORKFLOW-RULES.md for complete git workflow documentation**

## 📦 Deployment (Continuous Deployment)

**Reference**: @docs/DEPLOYMENT-README.md for complete deployment documentation

### Quick Deployment Guide

#### Standard Release (Beta)

```bash
# Step 1: Bump version
./scripts/bump-version.sh 1.2.0-beta.1

# Step 2: Commit and tag
git commit -am "chore: Beta release v1.2.0-beta.1"
git tag v1.2.0-beta.1

# Step 3: Push tag (triggers automated deployment)
git push && git push --tags

# Step 4: Monitor GitHub Actions
# iOS: Deploys to TestFlight automatically
# Android: Deploys to Play Console Internal Testing
```

**See @docs/DEPLOYMENT-README.md for production releases, hotfixes, and rollback procedures**

## 💱 Multi-Currency Architecture

**Reference**: @data-models-spec.md and @ui-design-spec.md for complete specifications

### Conditional UI Design
- **Single Currency → Single List** (no tabs when only one currency exists)
- **Multiple Currencies → Tabbed Interface** (tabs appear when 2+ currencies exist)
- **Universal Currency Support** - Any ISO 4217 currency via voice
- **Dynamic tab creation** when new currency detected from voice
- **Same UI per currency**: expense list + total at top

### Default Currency Initialization

**Core Principle**: App ALWAYS has a default currency based on device locale.

**Locale Mappings:**
- UAE/Arabic locales → AED
- US locales → USD
- UK locales → GBP
- India locales → INR
- Saudi Arabia → SAR
- EU locales → EUR
- Fallback → USD

### Currency Flow
1. **First Launch**: Initialize default (locale-based) → Onboarding → Request Permissions → Select/Confirm Default Currency
2. **Empty State**: ALWAYS shows default currency total (e.g., "AED 0.00")
3. **Single Currency**: Show simple list (no tabs) with default currency
4. **Multiple Currencies**: Show tabbed interface with currency switcher
5. **Voice Detection**: Auto-detect currency from voice ("50 dirhams" → AED)
6. **Universal Support**: Detect ANY currency ("100 kuna" → create HRK tab)
7. **Fallback**: Use default currency if none specified in voice

## 📱 UI/UX Principles

**Reference**: @ui-design-spec.md for complete design specifications

- Voice-first design philosophy
- Multi-currency tabbed interface
- Currency-specific expense isolation
- 3-tap max for manual operations
- Instant confirmation for voice commands
- Accessibility (VoiceOver/TalkBack) from day 1
- Onboarding-first user experience
- Consistent currency formatting: 1,234.56 (all currencies)
- Dynamic total in header (updates with tab changes)
- **Landscape mode**: Portrait only for mobile phones

## 📱 UI Components

**Reference**: @docs/REUSABLE-COMPONENTS.md for complete component catalog

**Core Principle**: Always use reusable components when available. Don't create inline UI elements if a component exists.

**Available Components:**
- **PrimaryButton** - Standard 56dp/pt primary action button
- **AppHeaderCard** - Header with title and total display
- **EmptyStateView** - Consistent empty state messaging
- **ExpenseRowView** - Individual expense list items

**Component Usage Example:**
```swift
// iOS - Always use PrimaryButton for primary actions
PrimaryButton(text: "Continue", action: completeOnboarding)
    .padding(.horizontal, 24)
```

```kotlin
// Android - Always use PrimaryButton for primary actions
PrimaryButton(text = "Continue", onClick = { completeOnboarding() })
```

**See @docs/REUSABLE-COMPONENTS.md for complete catalog and usage guidelines**

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

## 🎯 Success Metrics

**This Week**: Voice-log a test expense successfully
**Quality Gates**: All tests pass, no security issues
**Performance**: Voice processing under target times

---

## 🚨 FINAL REMINDER: TEST DRIVEN DEVELOPMENT IS MANDATORY

**Before writing ANY production code, ask yourself:**
1. Do I have a failing test for this?
2. Have I run the test to confirm it fails?
3. Am I writing the minimal code to make it pass?

**If the answer to any of these is "NO", STOP and write the test first.**

**TDD is not optional. It's how we build quality software in this project.**

---

*Smart references to comprehensive docs, focused working context for development*
