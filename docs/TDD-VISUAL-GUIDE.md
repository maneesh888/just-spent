# TDD Enforcement Visual Guide

## 🎯 The Problem We're Solving

### ❌ Before: Messy Commit History
```
* fix: typo in currency formatter
* fix: another bug in formatter
* fix: forgot to handle edge case
* fix: currency formatter actually working now
* feat: Add currency formatter
```

### ✅ After: Clean Commit History
```
* feat: Add currency formatter with comprehensive tests
```

## 🔄 TDD Workflow Enforced by Hooks

```
┌─────────────────────────────────────────────────────────┐
│                  RED-GREEN-REFACTOR                     │
└─────────────────────────────────────────────────────────┘

1. 🔴 RED Phase: Write Failing Test
   ┌───────────────────────────────┐
   │ Write test that fails         │
   │ Run: xcodebuild test          │
   │ Result: ❌ Test fails ✓       │
   └───────────────────────────────┘
                  ↓

2. 🟢 GREEN Phase: Make Test Pass
   ┌───────────────────────────────┐
   │ Write minimal code            │
   │ Run: xcodebuild test          │
   │ Result: ✅ Test passes ✓      │
   └───────────────────────────────┘
                  ↓

3. ♻️  REFACTOR Phase: Improve Code
   ┌───────────────────────────────┐
   │ Clean up implementation       │
   │ Run: xcodebuild test          │
   │ Result: ✅ Still passes ✓     │
   └───────────────────────────────┘
                  ↓

4. 📝 COMMIT Phase: Save Changes
   ┌───────────────────────────────┐
   │ git commit -m "feat: ..."     │
   │ Pre-commit hook runs:         │
   │  • Validates test coverage    │
   │  • Runs ./local-ci.sh --quick │
   │ Result: ✅ Commit allowed ✓   │
   └───────────────────────────────┘
```

## 🛡️ Pre-Commit Hook Flow

```
┌───────────────────────────────────────────────────┐
│            git commit -m "message"                │
└─────────────────┬─────────────────────────────────┘
                  ↓
    ┌─────────────────────────────┐
    │  Pre-Commit Hook Activates  │
    └─────────────┬───────────────┘
                  ↓
    ┌─────────────────────────────┐
    │  Check: WIP commit?         │
    └───┬──────────────────┬──────┘
        │ Yes              │ No
        ↓                  ↓
    ┌───────┐      ┌──────────────────────┐
    │ ALLOW │      │ Validate Test Coverage│
    │ (WIP) │      └──────┬───────────────┘
    └───────┘             ↓
                  ┌──────────────────────┐
                  │ Missing test files?  │
                  └───┬──────────────┬───┘
                      │ Yes          │ No
                      ↓              ↓
                  ┌───────┐   ┌─────────────────┐
                  │ BLOCK │   │ Run Quick Tests │
                  │  ❌   │   └────┬────────────┘
                  └───────┘        ↓
                           ┌───────────────┐
                           │ Tests pass?   │
                           └──┬────────┬───┘
                              │ Yes    │ No
                              ↓        ↓
                         ┌────────┐ ┌───────┐
                         │ ALLOW  │ │ BLOCK │
                         │   ✅   │ │  ❌   │
                         └────────┘ └───────┘
```

## 🔧 Git Amend Workflow

### Scenario: You Just Committed, Then Found a Bug

```
Timeline: Commit → Bug Found → Fix → Amend

┌────────────────────────────────────────────────┐
│ Step 1: Initial Commit                         │
├────────────────────────────────────────────────┤
│ $ git commit -m "feat: Add formatter"          │
│ ✅ Commit created: abc123                      │
└────────────────────────────────────────────────┘
                     ↓
┌────────────────────────────────────────────────┐
│ Step 2: Bug Discovered Immediately             │
├────────────────────────────────────────────────┤
│ 💡 "Oh no! I forgot to handle null case"      │
└────────────────────────────────────────────────┘
                     ↓
┌────────────────────────────────────────────────┐
│ Step 3: Fix the Bug                            │
├────────────────────────────────────────────────┤
│ • Edit code to handle null                     │
│ • Add test case for null                       │
│ • Run: ./local-ci.sh --all --quick             │
│ ✅ Tests pass                                  │
└────────────────────────────────────────────────┘
                     ↓
┌────────────────────────────────────────────────┐
│ Step 4: Amend the Commit                       │
├────────────────────────────────────────────────┤
│ $ git add <fixed-files>                        │
│ $ git commit --amend --no-edit                 │
│ ✅ Commit updated: abc123 (same ID!)           │
└────────────────────────────────────────────────┘
                     ↓
┌────────────────────────────────────────────────┐
│ Result: Clean History                          │
├────────────────────────────────────────────────┤
│ Only one commit:                               │
│ * abc123 feat: Add formatter                   │
│                                                │
│ Instead of messy:                              │
│ * def456 fix: Handle null case                 │
│ * abc123 feat: Add formatter                   │
└────────────────────────────────────────────────┘
```

## 🚦 Decision Tree: Should I Amend?

```
┌─────────────────────────────┐
│ Just committed code?        │
└───────┬─────────────────────┘
        ↓
┌─────────────────────────────┐
│ Found bug immediately?      │
└───────┬─────────────────────┘
        ↓
┌─────────────────────────────┐
│ Commit pushed to remote?    │
└───┬─────────────────┬───────┘
    │ NO              │ YES
    ↓                 ↓
┌──────────────┐  ┌────────────────┐
│ ✅ USE AMEND │  │ ❌ DON'T AMEND │
│              │  │ Create fix     │
│ git commit   │  │ commit instead │
│ --amend      │  │                │
└──────────────┘  └────────────────┘
```

## 📊 Hook Output Examples

### ✅ Success: All Checks Pass

```
🔍 Pre-Commit: Running TDD Enforcement Checks...
================================================

📝 Analyzing staged files...

📋 Checking test coverage for iOS...
✅ All modified files have corresponding tests

🧪 Running quick test suite...

⏳ Building iOS app...
✅ iOS build completed (45s)

⏳ Running iOS unit tests...
✅ iOS unit tests passed (2m 15s)

========================================
✅ All pre-commit checks passed!
========================================

📊 Summary:
  ✅ All tests passing
  ✅ Test coverage verified
  ✅ Ready to commit
```

### ❌ Blocked: Missing Tests

```
🔍 Pre-Commit: Running TDD Enforcement Checks...
================================================

📝 Analyzing staged files...

📋 Checking test coverage for iOS...
❌ Missing test files for:
  - ios/JustSpent/Utils/CurrencyFormatter.swift

❌ Missing test coverage!

📚 TDD Requirement:
  All production code must have corresponding test files.

To fix:
  1. Create test files for the missing files listed above
  2. Write tests BEFORE implementing the feature
  3. Follow the Red-Green-Refactor cycle

To bypass (NOT RECOMMENDED):
  git commit --no-verify -m 'WIP: your message'
```

### ❌ Blocked: Tests Failing

```
🔍 Pre-Commit: Running TDD Enforcement Checks...
================================================

📝 Analyzing staged files...
✅ All modified files have corresponding tests

🧪 Running quick test suite...

⏳ Running iOS unit tests...
❌ iOS unit tests failed!

Test Case '-[CurrencyFormatterTests testFormatAED]' failed.
Expected: "د.إ 1,234.56"
Actual: "AED 1,234.56"

========================================
❌ Tests failed! Cannot commit.
========================================

📚 TDD Reminder:
  1. 🔴 RED: Write a failing test first
  2. 🟢 GREEN: Write minimal code to pass the test
  3. ♻️  REFACTOR: Clean up while keeping tests green

To fix:
  1. Review failed tests in terminal output above
  2. Fix the failing tests
  3. Run './local-ci.sh --all --quick' to verify
  4. Try commit again
```

### ⚠️ WIP Bypass

```
🔍 Pre-Commit: Running TDD Enforcement Checks...
================================================

⚠️  WIP commit detected - skipping pre-commit checks
Remember to run tests before final commit!
```

### 💡 Post-Commit Guidance

```
⚠️  Fix Commit Detected

💡 Pro Tip: Consider using 'git commit --amend' next time:

  When you commit code and immediately discover a bug:
  1. Fix the bug
  2. Run tests: ./local-ci.sh --all --quick
  3. Stage fixes: git add <files>
  4. Amend commit: git commit --amend --no-edit

  This keeps your history clean by updating the previous commit
  instead of creating a separate fix commit.

  ⚠️  Only use --amend BEFORE pushing to remote!

✅ Commit successful!

📚 TDD Reminder:
  Remember the Red-Green-Refactor cycle for your next commit:
  1. 🔴 Write failing test first
  2. 🟢 Implement minimal code to pass
  3. ♻️  Refactor while keeping tests green
```

## 🎯 Quick Command Reference

### Normal Development
```bash
# 1. Write test first
touch Tests/FeatureTests.swift

# 2. Implement feature
# ... code ...

# 3. Run tests
./local-ci.sh --all --quick

# 4. Commit (hook runs automatically)
git commit -m "feat: Add feature"
```

### Immediate Fix (Use Amend)
```bash
# Just committed
git commit -m "feat: Add feature"

# Found bug! Fix it
# ... fix code ...
./local-ci.sh --all --quick

# Amend the commit
git add .
git commit --amend --no-edit
```

### Work in Progress
```bash
# Save WIP (bypass hook)
git commit -m "WIP: Implementing feature"

# Or use --no-verify
git commit --no-verify -m "Saving work"
```

## 🏆 Benefits at a Glance

```
┌─────────────────────────────────────────────────┐
│              BEFORE TDD ENFORCEMENT             │
├─────────────────────────────────────────────────┤
│ ❌ Commits with failing tests                   │
│ ❌ Code without test coverage                   │
│ ❌ Messy "fix" commits in history               │
│ ❌ Bugs discovered after push                   │
│ ❌ Manual test running (often skipped)          │
└─────────────────────────────────────────────────┘

                      ↓ ↓ ↓

┌─────────────────────────────────────────────────┐
│              AFTER TDD ENFORCEMENT              │
├─────────────────────────────────────────────────┤
│ ✅ All commits have passing tests               │
│ ✅ 85%+ test coverage maintained                │
│ ✅ Clean, professional commit history           │
│ ✅ Bugs caught before commit                    │
│ ✅ Automatic test running (can't skip)          │
└─────────────────────────────────────────────────┘
```

---

**Remember**: The hooks are there to help you, not annoy you. They enforce best practices that lead to higher quality code and cleaner git history!
