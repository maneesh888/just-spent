# Just Spent - Claude Code Memory

@just-spent-master-plan.md
@data-models-spec.md
@TESTING-GUIDE.md
@docs/GIT-WORKFLOW-RULES.md

## 🎯 Current Context

**Status**: Android Multi-Currency UI Complete → iOS Implementation
**Phase**: Foundation (Week 1-2)
**Priority**: iOS implementation matching Android design
**Developer**: Solo, iOS expertise, Android learning

**Recent Completion:**
- ✅ Android multi-currency tabbed UI fully implemented
- ✅ Dynamic total calculation per currency
- ✅ Consistent currency formatting (. decimal, , grouping)
- ✅ Header card design with gradient background
- ✅ FAB with recording indicator
- ✅ Comprehensive UI design documentation

**Reference Documents:**
- @ui-design-spec.md - Complete Android UI implementation details

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
   - Write the test for the feature/fix BEFORE any implementation
   - Run the test and verify it fails (for the right reason)
   - Never skip this step, even for "simple" changes

2. **🟢 GREEN**: Write minimal code to pass the test
   - Implement just enough code to make the test pass
   - Don't add extra features or "nice-to-haves"
   - Run the test and verify it passes

3. **♻️ REFACTOR**: Clean up the code
   - Improve code quality while keeping tests green
   - Apply SOLID principles
   - Ensure readability and maintainability

### TDD Rules for This Project

- ✅ **Test first, code second** - No exceptions
- ✅ **One test at a time** - Focus on one behavior per test
- ✅ **Run tests frequently** - After every small change
- ✅ **Commit only when green** - All tests must pass before commit
- ✅ **Test behavior, not implementation** - Focus on what, not how
- ❌ **Never write production code without a failing test**
- ❌ **Never commit failing tests** (except in WIP branches with --no-verify)
- ❌ **Never skip tests** because "it's too simple" or "I'll add them later"

### TDD for iOS (XCTest)
```swift
// 1. RED: Write failing test
func testCurrencyFormatter_formatAED_returnsCorrectFormat() {
    let result = CurrencyFormatter.shared.format(
        amount: Decimal(1234.56),
        currency: .AED
    )
    XCTAssertEqual("د.إ 1,234.56", result) // FAILS - formatter doesn't exist
}

// 2. GREEN: Implement minimal code
class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    func format(amount: Decimal, currency: Currency) -> String {
        return "\(currency.symbol) 1,234.56" // Simplest implementation
    }
}

// 3. REFACTOR: Improve implementation while keeping tests green
```

### TDD for Android (JUnit + Kotlin)
```kotlin
// 1. RED: Write failing test
@Test
fun formatAED_withSymbolAndGrouping_returnsCorrectFormat() {
    val result = CurrencyFormatter.format(
        amount = BigDecimal("1234.56"),
        currency = Currency.AED
    )
    assertEquals("د.إ 1,234.56", result) // FAILS - formatter doesn't exist
}

// 2. GREEN: Implement minimal code
object CurrencyFormatter {
    fun format(amount: BigDecimal, currency: Currency): String {
        return "${currency.symbol} 1,234.56" // Simplest implementation
    }
}

// 3. REFACTOR: Improve implementation while keeping tests green
```

### When Claude Code Implements Features

**Every implementation request MUST follow this pattern:**

1. **Ask for clarification** if test requirements are unclear
2. **Write the test file first** with failing tests
3. **Run tests** and confirm they fail
4. **Implement the feature** with minimal code
5. **Run tests** and confirm they pass
6. **Refactor** if needed while keeping tests green
7. **Show test results** to confirm all tests pass

### Pre-Commit Checklist (TDD Edition)

Before every commit, verify:
- [ ] All new code has corresponding tests
- [ ] Tests were written BEFORE implementation
- [ ] All tests pass (`./local-ci.sh --all --quick`)
- [ ] Test coverage remains ≥85%
- [ ] No test files are skipped or commented out

### TDD Benefits Reminder

- ✅ **Confidence**: Tests prove the code works
- ✅ **Design**: Tests force better API design
- ✅ **Documentation**: Tests show how to use the code
- ✅ **Refactoring Safety**: Change code without fear
- ✅ **Bug Prevention**: Catch issues before they reach production
- ✅ **Faster Development**: Less debugging, more building

---

**REMEMBER: If you don't have a failing test, you don't write production code. Period.**

---

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

Reference: @comprehensive-test-plan.md, @TESTING-GUIDE.md

**⚠️ CRITICAL**: All tests must be written BEFORE implementation (TDD mandatory)

### Coverage Targets
- Unit Tests: 85% minimum (written BEFORE implementation)
- Voice Integration: All patterns tested (test-first approach)
- Performance: <1.5s voice processing (with performance tests)
- Security: OWASP Mobile Top 10 compliance (with security tests)

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

Reference: @LOCAL-CI.md for complete documentation

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
- Generates HTML reports + macOS notifications
- Zero cost, no network dependency

**GitHub Actions** (for production):
- Runs automatically on `main` branch only
- Safety net for production code
- Can be manually triggered for any branch
- Team visibility and PR badges

### When to Use What

| Task | Use Local CI | Use GitHub Actions |
|------|--------------|-------------------|
| During development | ✅ Always | ❌ Not needed |
| Before commit | ✅ Auto (hook) | ❌ Not needed |
| Feature branch | ✅ Run manually | ⚠️ Optional (manual trigger) |
| PR to main | ✅ Good practice | ✅ Runs automatically |
| After merge to main | ❌ Not needed | ✅ Runs automatically |

### Pre-Commit Hook

Automatically enforces TDD practices before each commit:
- ✅ Validates test coverage for all changed files
- ✅ Runs `./local-ci.sh --all --quick` to verify tests pass
- ✅ Blocks commits with failing tests or missing test coverage

**To bypass** (for WIP commits only):
```bash
git commit --no-verify -m "WIP: message"
# Or start message with "WIP:" to auto-bypass
git commit -m "WIP: Implementing feature"
```

**When to bypass**: Only for WIP commits on feature branches. Never bypass on main branch.

### Git Amend Workflow

When you discover a bug immediately after committing, use `git commit --amend` instead of creating a "fix" commit:

```bash
# You just committed code
git commit -m "feat: Add currency formatter"

# You discover a bug immediately
# Fix the bug, run tests
./local-ci.sh --all --quick

# Stage the fixes
git add <fixed-files>

# Amend the commit (keeps history clean)
git commit --amend --no-edit
```

**⚠️ IMPORTANT**: Only use `--amend` BEFORE pushing to remote!

**See @docs/GIT-WORKFLOW-RULES.md for complete git workflow documentation**

### Viewing Results

**Terminal**: Colored output with ✅/❌ status
**HTML Report**: Auto-opens in browser after each run
**Logs**: Saved in `.ci-results/` directory
**Notifications**: macOS alerts on completion

### Manual GitHub Actions Trigger

1. Go to: https://github.com/YOUR_USERNAME/just-spent/actions
2. Click "PR Checks" workflow
3. Click "Run workflow" → Select branch → Run

### Performance Comparison

| Metric | Local CI | GitHub Actions |
|--------|----------|----------------|
| Full suite | 5-10 min | 11-12 min |
| Quick mode | 2-3 min | N/A |
| Failure rate | ~5% | ~30% (network issues) |
| Cost | Free | GitHub minutes |

## 🚀 Current Sprint Tasks

### Multi-Currency Tabbed UI Implementation (Android)
1. ✅ Currency onboarding screens
2. ✅ Onboarding completion flags in UserPreferences
3. ✅ Onboarding navigation logic on app launch
4. ✅ Currency tab bar component (ScrollableTabRow)
5. ✅ Dynamic tab generation based on expenses
6. ✅ Per-currency expense filtering
7. ✅ Per-currency total calculation in header
8. ✅ Tab view integration into MainContentScreen
9. ✅ Empty states and edge cases
10. ✅ Complete tabbed currency flow
11. ✅ Consistent currency formatting (CurrencyFormatter)
12. ✅ Comprehensive UI documentation

### Next: iOS Implementation
Reference @ui-design-spec.md for complete design specifications.

**iOS Tasks (Priority Order):**
1. ⏳ Implement CurrencyFormatter utility (match Android)
2. ⏳ Create header card with dynamic total
3. ⏳ Add gradient background
4. ⏳ Implement custom FAB equivalent
5. ⏳ Build expense row design
6. ⏳ Create empty state screen
7. ⏳ Implement single currency screen
8. ⏳ Build multi-currency tabbed interface
9. ⏳ Add voice indicator icon
10. ⏳ Implement swipe to delete

### Code Generation Requests (iOS)
When asking Claude Code, ALWAYS follow TDD:
- "Write tests first for CurrencyFormatter utility, then implement in Swift matching Android design"
- "Write tests for header card component, then create with gradient background for SwiftUI"
- "Write tests for FAB component, then build custom FAB with recording indicator in SwiftUI"
- "Write tests for currency tabs, then implement scrollable currency tabs for SwiftUI"
- "Write tests for total calculation, then create dynamic total calculation matching Android pattern"

**REMINDER**: Every request should start with "Write tests first for..." to enforce TDD

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

### Default Currency Initialization (NEW!)
**Core Principle**: App ALWAYS has a default currency based on device locale. This ensures:
- ✅ Modules are independent (no need to check onboarding state)
- ✅ Empty state shows meaningful currency ("AED 0.00" not just "0.00")
- ✅ Voice commands have intelligent fallback

**Initialization Flow:**
```
App Launch
    ↓
Check if default currency exists in UserPreferences
    ↓
    ├─ Not Set → Detect from device locale
    │             (e.g., UAE locale → AED, US locale → USD)
    │             ↓
    │          Save as default currency
    │
    └─ Already Set → Use existing default
    ↓
Continue to onboarding check
```

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

### Onboarding Requirements
- **Step 1: Welcome** - App introduction
- **Step 2: Permissions** - Siri/Assistant, Microphone (required), Notifications (optional)
- **Step 3: Currency Selection** - Choose from 6 predefined currencies
  - **Default Pre-Selected**: Locale-based currency is pre-selected
  - **User Choice**: User can accept default OR choose different currency
  - **Update Default**: If user chooses different, update default currency
- **Must complete** before main app access
- Save to UserPreferences/DataStore with `hasCompletedOnboarding` flag

## 📱 UI/UX Principles

- Voice-first design philosophy
- Multi-currency tabbed interface
- Currency-specific expense isolation
- 3-tap max for manual operations
- Instant confirmation for voice commands
- Accessibility (VoiceOver/TalkBack) from day 1
- Onboarding-first user experience
- Consistent currency formatting: 1,234.56 (all currencies)
- Dynamic total in header (updates with tab changes)
- Gradient background (blue → purple, subtle)

**Design Reference:** See @ui-design-spec.md for complete specifications

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