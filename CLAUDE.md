# Just Spent - Claude Code Memory

@just-spent-master-plan.md
@data-models-spec.md
@TESTING-GUIDE.md
@docs/GIT-WORKFLOW-RULES.md
@docs/REUSABLE-COMPONENTS.md
@docs/DEPLOYMENT-README.md

## 🎯 Current Context

**Status**: Core UI Complete (iOS & Android) → Voice Integration Phase
**Phase**: Phase 3 (Week 5-6) - Voice Integration & Testing (95% complete)
**Priority**: Siri & Google Assistant integration for voice-activated expense logging
**Developer**: Solo, iOS expertise, Android learning
**Deployment**: Fully automated CI/CD pipeline ready (TestFlight & Play Store)

**Recent Completion:**
- ✅ **Complete CI/CD Pipeline** - Fully automated iOS and Android deployment
- ✅ GitHub Actions workflows for TestFlight and Play Store
- ✅ Fastlane automation for both platforms
- ✅ Automated version management and build numbering
- ✅ Comprehensive deployment documentation (98KB, 4 guides)
- ✅ Android multi-currency tabbed UI fully implemented
- ✅ iOS multi-currency UI with custom header
- ✅ Dynamic total calculation per currency
- ✅ Consistent currency formatting (. decimal, , grouping)
- ✅ Reusable components library (PrimaryButton, Header, EmptyState)

**Reference Documents:**
- @ui-design-spec.md - Complete Android UI implementation details
- @docs/REUSABLE-COMPONENTS.md - UI component catalog and usage guide

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

## 📦 Deployment (Continuous Deployment)

Reference: @docs/DEPLOYMENT-README.md for complete deployment documentation

### Overview

Just Spent has a **fully automated continuous deployment (CD) pipeline** that deploys to App Store and Play Store with a single git tag.

**Architecture:**
```
Git Tag → GitHub Actions → Build & Sign → Deploy to App Stores
```

### Quick Deployment Guide

#### 1. Standard Release (Beta)

```bash
# Step 1: Bump version
./scripts/bump-version.sh 1.2.0-beta.1

# Step 2: Commit and tag
git commit -am "chore: Beta release v1.2.0-beta.1"
git tag v1.2.0-beta.1

# Step 3: Push tag (triggers automated deployment)
git push && git push --tags

# Step 4: Monitor GitHub Actions
# - iOS: Deploys to TestFlight automatically
# - Android: Deploys to Play Console Internal Testing
# Go to: https://github.com/YOUR_USERNAME/just-spent/actions

# Step 5: Test beta builds
# - iOS: TestFlight app (team members)
# - Android: Play Console Internal Testing (up to 100 testers)
```

#### 2. Production Release

```bash
# Step 1: Bump to production version
./scripts/bump-version.sh 1.2.0

# Step 2: Commit and tag
git commit -am "chore: Release v1.2.0"
git tag v1.2.0

# Step 3: Push tag
git push && git push --tags

# Step 4: Monitor deployment
# - iOS: Builds → TestFlight → Manual submission to App Store
# - Android: Builds → Internal → Manual promotion to Production

# Step 5: Promote to production
# - iOS: Via App Store Connect (24-48 hour review)
# - Android: Via Play Console (phased rollout: 10% → 50% → 100%)
```

#### 3. Hotfix Release

```bash
# Step 1: Create hotfix branch
git checkout -b hotfix/critical-bug

# Step 2: Fix bug with tests (TDD required!)
./local-ci.sh --all --quick

# Step 3: Bump patch version
./scripts/bump-version.sh 1.2.1

# Step 4: Merge and deploy
git checkout main
git merge hotfix/critical-bug
git tag v1.2.1
git push && git push --tags

# Timeline: 1-3 hours (emergency deployment)
```

### Deployment Workflows

#### iOS Deployment (`.github/workflows/deploy-ios.yml`)

**Triggers:**
- Git tags matching `v*` (e.g., `v1.0.0`, `v1.0.0-beta.1`)
- Manual workflow dispatch

**Pipeline:**
1. Setup Xcode 26.0 on macOS-26
2. Install Ruby dependencies (Fastlane)
3. Import distribution certificates
4. Install provisioning profiles
5. Run unit tests (XCTest)
6. Build signed IPA
7. Upload to TestFlight (automatic)

**Duration:** ~10-15 minutes

**Output:** IPA uploaded to TestFlight

#### Android Deployment (`.github/workflows/deploy-android.yml`)

**Triggers:**
- Git tags matching `v*` (excluding `v*-ios`)
- Manual workflow dispatch

**Pipeline:**
1. Setup Android SDK + Java 17
2. Install Ruby dependencies (Fastlane)
3. Decode keystore from GitHub Secrets
4. Create keystore.properties
5. Run unit tests (JUnit)
6. Build signed AAB (App Bundle)
7. Upload to Play Console Internal Testing

**Duration:** ~8-12 minutes

**Output:** AAB uploaded to Play Console Internal track

### Fastlane Lanes

#### iOS Lanes (`ios/fastlane/Fastfile`)

**Deployment lanes:**
- `build_ipa` - Build signed IPA with automatic code signing
- `deploy_testflight` - Upload to TestFlight
- `deploy_appstore` - Submit for App Store review
- `beta` - Complete beta workflow (test + build + deploy)
- `release` - Full production release workflow

**Utility lanes:**
- `screenshots` - Generate App Store screenshots
- `upload_metadata` - Upload metadata to App Store Connect

**Usage in GitHub Actions:**
```yaml
- name: Deploy to TestFlight
  run: |
    cd ios
    bundle exec fastlane deploy_testflight
```

#### Android Lanes (`android/fastlane/Fastfile`)

**Deployment lanes:**
- `build_aab` - Build signed Android App Bundle
- `deploy_internal` - Deploy to Internal Testing
- `deploy_beta` - Deploy to Beta (Closed Testing)
- `deploy_production` - Deploy with phased rollout
- `promote_to_beta` - Promote Internal → Beta
- `promote_to_production` - Promote Beta → Production
- `increase_rollout` - Increase rollout percentage
- `complete_rollout` - Complete rollout to 100%

**Utility lanes:**
- `screenshots` - Generate Play Store screenshots
- `upload_metadata` - Upload metadata to Play Console

**Usage in GitHub Actions:**
```yaml
- name: Deploy to Play Console
  run: |
    cd android
    bundle exec fastlane deploy_internal
```

### Version Management

#### Semantic Versioning (SemVer)

Format: `MAJOR.MINOR.PATCH[-PRERELEASE]`

**Examples:**
- `1.0.0` - Initial release
- `1.1.0` - New feature (minor version bump)
- `1.1.1` - Bug fix (patch version bump)
- `1.2.0-beta.1` - Beta release
- `1.2.0-rc.1` - Release candidate

#### Version Bump Script

```bash
# Usage
./scripts/bump-version.sh <version>

# What it does:
# - Updates iOS Info.plist (CFBundleShortVersionString + build number)
# - Updates Android build.gradle (versionName + versionCode)
# - Generates timestamp-based build numbers (YYYYMMDDHHMM)
# - Shows git workflow next steps

# Examples
./scripts/bump-version.sh 1.2.3          # Release
./scripts/bump-version.sh 1.2.3-beta.1   # Beta
./scripts/bump-version.sh 1.2.3-rc.1     # Release candidate
```

### Deployment Tracks

#### iOS Distribution Tracks

```
TestFlight Internal → TestFlight External → App Store
     (Instant)          (24-48h review)      (Full review)
   Team members       Up to 10,000 testers   Public release
```

**Promotion:**
1. Automatic deployment to TestFlight Internal
2. Manual promotion to TestFlight External (via App Store Connect)
3. Manual submission to App Store (via App Store Connect)

#### Android Distribution Tracks

```
Internal Testing → Beta (Closed) → Production (Phased Rollout)
    (Instant)         (Instant)        10% → 50% → 100%
  100 testers      Unlimited testers   Day 1  Day 3  Day 5
```

**Promotion:**
1. Automatic deployment to Internal Testing
2. Manual promotion to Beta via Play Console or Fastlane:
   ```bash
   cd android
   bundle exec fastlane promote_to_beta
   ```
3. Manual promotion to Production with phased rollout:
   ```bash
   cd android
   bundle exec fastlane promote_to_production rollout_percentage:0.1
   ```

### Secrets Management

**Required GitHub Secrets:**

**iOS (7 secrets):**
- `IOS_CERTIFICATES_P12` - Distribution certificate (base64 encoded)
- `IOS_CERTIFICATES_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE` - Provisioning profile (base64 encoded)
- `APPLE_ID` - Your Apple ID
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- `APPLE_TEAM_ID` - Team ID (10 characters)
- `KEYCHAIN_PASSWORD` - CI keychain password

**Android (5 secrets):**
- `ANDROID_KEYSTORE_BASE64` - Upload keystore (base64 encoded)
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password
- `PLAY_STORE_JSON_KEY` - Service account JSON (base64 encoded)

**Security:**
- All secrets encrypted with libsodium sealed boxes
- Masked in logs (appear as `***`)
- Never exposed to code (only environment variables)

### Monitoring & Rollback

#### Post-Deployment Checklist

**First 24 Hours:**
- [ ] Monitor crash-free rate (target: ≥99.5%)
- [ ] Check for 1-star reviews spike
- [ ] Verify performance metrics stable
- [ ] No critical bugs reported

**Android Phased Rollout:**
- Day 1: 10% rollout → Monitor closely
- Day 3: 50% rollout → Check metrics
- Day 5: 100% rollout → Full deployment

#### Rollback Procedures

**iOS:**
```
1. Remove from sale in App Store Connect
2. Release emergency patch version
3. Request expedited review
Timeline: 24-48 hours
```

**Android:**
```bash
# Option 1: Halt rollout
cd android
bundle exec fastlane halt_rollout

# Option 2: Rollback to previous version (automatic downgrade)
# Via Play Console → Production → Manage releases → Rollback

Timeline: Instant
```

### Deployment Documentation

**Comprehensive guides:**
- [DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md) - Complete CD concepts (28KB)
- [SECRETS-SETUP-GUIDE.md](docs/SECRETS-SETUP-GUIDE.md) - Credential setup (25KB)
- [DEPLOYMENT-CHECKLIST.md](docs/DEPLOYMENT-CHECKLIST.md) - Operational runbooks (30KB)
- [DEPLOYMENT-README.md](docs/DEPLOYMENT-README.md) - Quick reference (15KB)

### Common Deployment Scenarios

#### Scenario 1: Beta Testing

```bash
# Deploy to beta for testing
./scripts/bump-version.sh 1.2.0-beta.1
git commit -am "chore: Beta release v1.2.0-beta.1"
git tag v1.2.0-beta.1
git push --tags

# Wait for GitHub Actions to complete (~10-15 min)
# Test on TestFlight (iOS) and Play Console Internal (Android)
```

#### Scenario 2: Production Release

```bash
# After successful beta testing
./scripts/bump-version.sh 1.2.0
git commit -am "chore: Release v1.2.0"
git tag v1.2.0
git push --tags

# iOS: Submit for review via App Store Connect
# Android: Promote to production via Play Console
```

#### Scenario 3: Emergency Hotfix

```bash
# Critical bug in production
git checkout -b hotfix/critical-bug
# Fix bug, test with ./local-ci.sh --all --quick
./scripts/bump-version.sh 1.2.1
git checkout main && git merge hotfix/critical-bug
git tag v1.2.1
git push --tags

# Monitor closely, be ready to rollback if needed
```

### Troubleshooting

**Build Failed:**
1. Check GitHub Actions logs
2. Run `./local-ci.sh --all` locally to reproduce
3. Review pre-deployment checklist in DEPLOYMENT-CHECKLIST.md

**Certificate/Signing Issues:**
1. Verify secrets are correctly set in GitHub
2. Check certificate expiry dates
3. Regenerate if needed (see SECRETS-SETUP-GUIDE.md)

**App Review Rejected:**
1. Read rejection reason carefully
2. Fix issues mentioned
3. Bump patch version and redeploy

---

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

### UI Components

**Reference:** @docs/REUSABLE-COMPONENTS.md for complete component catalog

**Core Principle:** Always use reusable components when available. Don't create inline UI elements if a component exists.

**Available Components:**
- **PrimaryButton** - Standard 56dp/pt primary action button (blue, full width)
  - iOS: `PrimaryButton(text:action:enabled:accessibilityIdentifier:)`
  - Android: `PrimaryButton(text:onClick:enabled:testTag:)`
- **AppHeaderCard** - Header with title and total display
- **EmptyStateView** - Consistent empty state messaging
- **ExpenseRowView** - Individual expense list items

**When Creating New Components:**
1. Write tests FIRST (TDD mandatory)
2. Create both iOS and Android versions
3. Add to `docs/REUSABLE-COMPONENTS.md`
4. Follow naming: `ComponentName.swift` / `ComponentName.kt`
5. Location: `Views/Components/` (iOS) or `ui/components/` (Android)

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

**See @docs/REUSABLE-COMPONENTS.md for:**
- Complete component catalog
- Usage guidelines and examples
- Design specifications
- When to use each component
- Future planned components

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
- **Landscape mode**: Portrait only for mobile phones, portrait + landscape for tablets

**Design Reference:** See @ui-design-spec.md for complete specifications

**Testing Policy** (Updated 2025-11-11):
- ✅ Mobile phones: Portrait orientation only
- ✅ Tablets: Portrait and landscape orientations
- See @TESTING-GUIDE.md and @ios/TEST_STATUS_FINAL.md for details

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