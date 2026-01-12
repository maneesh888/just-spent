# Just Spent - Claude Code Memory

## Project Overview

**App**: Personal expense tracker with voice logging (Siri & Google Assistant)
**Platforms**: iOS (Swift/SwiftUI) & Android (Kotlin/Compose)
**Status**: Phase 3 - Voice Integration (95% complete)
**Tests**: 425/428 passing (99.3%)

## Tech Stack

- **iOS**: Swift 5.7+, SwiftUI, MVVM, Core Data, SiriKit
- **Android**: Kotlin 1.8+, Jetpack Compose, MVVM, Room, App Actions
- **Architecture**: Local-first, offline-capable, voice-optimized

## Critical Rules

### TDD is MANDATORY

All code changes MUST follow Test-Driven Development:
1. **RED**: Write failing test first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Clean up

Never write production code without a failing test.

### Code Standards

- SOLID principles required
- 80%+ test coverage
- Clean Architecture: Presentation → Domain → Data
- Commit only when all tests pass

## Quick Commands

```bash
# Run tests
./local-ci.sh --all --quick    # Fast: build + unit tests
./local-ci.sh --all            # Full: build + all tests

# iOS tests
cd ios/JustSpent && xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent -destination 'platform=iOS Simulator,name=iPhone 16'

# Android tests
cd android && ./test.sh unit   # Unit tests
cd android && ./test.sh all    # All tests

# Bypass pre-commit hook (WIP only)
git commit --no-verify -m "WIP: message"
```

## Known Issues (Dec 2025)

- **Android**: 2 UI tests failing (timing issues in EditExpenseUITest)
- **iOS**: 1 UI test failing (multi-currency tab display)

---

## 📚 Documentation Index (Load On-Demand)

**IMPORTANT**: Do NOT load these files unless the task requires them. Read the file only when working on related functionality.

### When Working on Features/Architecture

| File | Load When... |
|------|-------------|
| `just-spent-master-plan.md` | Planning new features, checking project roadmap |
| `data-models-spec.md` | Modifying data models, database schemas, Core Data/Room |
| `ui-design-spec.md` | UI changes, styling, design tokens, multi-currency UI |

### When Working on Testing

| File | Load When... |
|------|-------------|
| `TESTING-GUIDE.md` | Writing tests, debugging test failures, test commands |
| `KNOWN_ISSUES.md` | Investigating known bugs, test failures |
| `android/TEST_STATUS_FINAL.md` | Debugging Android test issues specifically |
| `ios/TEST_STATUS_FINAL.md` | Debugging iOS test issues specifically |

### When Working on Voice Integration

| File | Load When... |
|------|-------------|
| `ios-siri-integration.md` | Implementing iOS Siri/SiriKit features |
| `android-assistant-integration.md` | Implementing Android Google Assistant |

### When Working on CI/CD & Git

| File | Load When... |
|------|-------------|
| `LOCAL-CI.md` | CI/CD issues, pipeline configuration, emulator problems |
| `docs/GIT-WORKFLOW-RULES.md` | Git workflow, commit conventions, hooks |
| `docs/DEPLOYMENT-README.md` | Deploying to App Store/Play Store |

### When Working on UI Components

| File | Load When... |
|------|-------------|
| `docs/REUSABLE-COMPONENTS.md` | Using/creating reusable UI components |

---

## Core Concepts (Brief Reference)

### Multi-Currency Architecture

- Single currency → Simple list (no tabs)
- Multiple currencies → Tabbed interface
- Default currency from device locale (AED for UAE, USD for US, etc.)
- Voice detection: "50 dirhams" → AED tab

### File Organization

```
ios/JustSpent/
├── Models/      # Core Data
├── Views/       # SwiftUI
├── ViewModels/  # Business logic
└── Services/    # Data/voice

android/app/src/main/java/com/justspent/
├── data/        # Room DB
├── ui/          # Compose screens
└── domain/      # Business logic
```

### Reusable Components

- **PrimaryButton** - 56dp/pt action button
- **AppHeaderCard** - Header with total
- **EmptyStateView** - Empty state messaging
- **ExpenseRowView** - Expense list items

---

*This is a lean context file. Load specific documentation only when needed for your current task.*
