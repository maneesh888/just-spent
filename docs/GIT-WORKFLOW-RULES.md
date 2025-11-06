# Just Spent - Git Workflow Rules

## Overview

This document defines the git workflow rules that enforce Test-Driven Development (TDD) and prevent committing faulty code.

## Core Principles

### 1. Never Commit Faulty Code

**Rule**: All commits must pass tests before being committed.

**Enforcement**:
- Pre-commit hook runs `./local-ci.sh --all --quick` automatically
- Hook validates test coverage for all changed files
- Commit is blocked if tests fail or coverage is missing

**Exception**: WIP commits on feature branches (use `--no-verify` sparingly)

### 2. Amend Instead of Fixing

**Rule**: When you discover a bug immediately after committing, amend the commit instead of creating a "fix" commit.

**Workflow**:
```bash
# You just committed code
git commit -m "feat: Add currency formatter"

# You discover a bug
# ❌ BAD: Create a fix commit
git commit -m "fix: Currency formatter bug"

# ✅ GOOD: Amend the original commit
# 1. Fix the bug
# 2. Run tests
./local-ci.sh --all --quick

# 3. Stage the fixes
git add <fixed-files>

# 4. Amend the commit (keeps history clean)
git commit --amend --no-edit

# Or amend with updated message
git commit --amend -m "feat: Add currency formatter (fixed edge case)"
```

**When to Use Amend**:
- ✅ Bug found immediately after committing
- ✅ Commit not pushed to remote yet
- ✅ You're the only one working on the branch
- ✅ Minor fixes or improvements to the last commit

**When NOT to Use Amend**:
- ❌ Commit already pushed to main/develop
- ❌ Commit is part of a PR that's been reviewed
- ❌ Other developers have pulled your changes
- ❌ Bug found in an older commit (use a fix commit)

### 3. Test-First Development

**Rule**: Always write tests before implementation code.

**Workflow**:
```bash
# 1. Create test file
touch ios/JustSpent/JustSpentTests/CurrencyFormatterTests.swift

# 2. Write failing test
# (edit test file with failing test)

# 3. Verify test fails
cd ios/JustSpent
xcodebuild test -scheme JustSpent

# 4. Implement minimal code to pass
# (edit source file)

# 5. Verify test passes
xcodebuild test -scheme JustSpent

# 6. Commit both test and implementation
git add JustSpentTests/CurrencyFormatterTests.swift
git add JustSpent/Utils/CurrencyFormatter.swift
git commit -m "feat: Add currency formatter with tests"
```

### 4. WIP Commits

**Rule**: Use WIP commits for work-in-progress, but clean them up before merging.

**Usage**:
```bash
# Create WIP commit (bypasses pre-commit checks)
git commit --no-verify -m "WIP: Implementing currency formatter"

# Or start message with "WIP:" to auto-bypass
git commit -m "WIP: Half-done feature"

# Before merging, squash WIP commits
git rebase -i HEAD~3  # Squash last 3 commits
```

**WIP Commit Guidelines**:
- ✅ Use on feature branches only
- ✅ Clearly mark with "WIP:" prefix
- ✅ Clean up before creating PR
- ❌ Never push WIP commits to main
- ❌ Don't leave WIP commits in PR

## Pre-Commit Hook

### What It Does

The pre-commit hook automatically:

1. **Checks for WIP commits**: Bypasses checks if commit message starts with "WIP:"
2. **Validates test coverage**: Ensures all modified code files have corresponding test files
3. **Runs quick tests**: Executes `./local-ci.sh --all --quick` to verify tests pass
4. **Blocks faulty commits**: Prevents commit if tests fail or coverage is missing

### Bypass Methods

**Method 1: Use --no-verify flag**
```bash
git commit --no-verify -m "WIP: your message"
```

**Method 2: Start message with "WIP:"**
```bash
git commit -m "WIP: Implementing feature"
```

**Method 3: Disable hook temporarily**
```bash
# Disable
rm .git/hooks/pre-commit

# Re-enable
./scripts/install-hooks.sh
```

### When to Bypass

**Acceptable Reasons**:
- ✅ Creating WIP commit on feature branch
- ✅ Saving work before switching branches
- ✅ Committing documentation-only changes
- ✅ Quick checkpoint during refactoring

**Unacceptable Reasons**:
- ❌ Tests are failing and you want to commit anyway
- ❌ Too lazy to write tests
- ❌ "I'll add tests later" mindset
- ❌ Committing to main branch

## Post-Commit Hook

### What It Does

The post-commit hook provides:

1. **Fix commit detection**: Warns when you create a fix commit
2. **Amend suggestion**: Reminds you to use `git commit --amend` next time
3. **TDD reminder**: Reinforces the Red-Green-Refactor cycle

### Example Output

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
```

## Common Scenarios

### Scenario 1: Committed Code, Found Bug

**❌ Wrong Approach**:
```bash
git commit -m "feat: Add currency formatter"
# Found bug
# Fix it
git commit -m "fix: Currency formatter bug"
```

**✅ Correct Approach**:
```bash
git commit -m "feat: Add currency formatter"
# Found bug
# Fix it
./local-ci.sh --all --quick
git add <fixed-files>
git commit --amend --no-edit
```

### Scenario 2: Multiple Small Fixes

**❌ Wrong Approach**:
```bash
git commit -m "feat: Add feature"
git commit -m "fix: Typo"
git commit -m "fix: Another typo"
git commit -m "fix: Format"
```

**✅ Correct Approach**:
```bash
git commit -m "feat: Add feature"
# Fix typo
git add <file>
git commit --amend --no-edit
# Fix another typo
git add <file>
git commit --amend --no-edit
# Fix format
git add <file>
git commit --amend --no-edit
```

### Scenario 3: Tests Failing

**❌ Wrong Approach**:
```bash
# Tests failing
git commit --no-verify -m "feat: Add feature (tests broken)"
# Push to main
git push
```

**✅ Correct Approach**:
```bash
# Tests failing
# Fix tests first
./local-ci.sh --all --quick
# All tests pass
git commit -m "feat: Add feature with passing tests"
git push
```

### Scenario 4: Work in Progress

**✅ Acceptable Approach**:
```bash
# On feature branch
git commit --no-verify -m "WIP: Half-done feature"
# Continue working
git commit --no-verify -m "WIP: More progress"
# Finish feature
git commit -m "feat: Complete feature"
# Squash WIP commits before PR
git rebase -i HEAD~3
```

## Git Commit Message Conventions

### Format

```
<type>: <subject>

<optional body>

<optional footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `docs`: Documentation changes
- `style`: Formatting changes
- `perf`: Performance improvements
- `chore`: Build/tooling changes
- `WIP`: Work in progress (bypasses hooks)

### Examples

```bash
# Feature with tests
git commit -m "feat: Add multi-currency support with tests"

# Bug fix with amend
git commit -m "fix: Currency formatter edge case"
git commit --amend --no-edit  # After finding another edge case

# Test-only commit
git commit -m "test: Add comprehensive currency formatter tests"

# WIP commit
git commit -m "WIP: Implementing voice command parser"
```

## Branch Protection Rules

### Main Branch

**Rules**:
- ✅ All tests must pass
- ✅ No WIP commits allowed
- ✅ Requires PR review
- ✅ CI must pass before merge
- ❌ No direct commits
- ❌ No force push
- ❌ No --no-verify allowed

### Feature Branches

**Rules**:
- ✅ Can have WIP commits (clean up before PR)
- ✅ Pre-commit hook enforced (unless --no-verify)
- ✅ Amend commits freely before pushing
- ⚠️ Force push allowed (use carefully)

### Develop Branch (if used)

**Rules**:
- ✅ All tests must pass
- ✅ No WIP commits
- ⚠️ May allow direct commits (team decision)
- ❌ No force push

## Troubleshooting

### Hook Won't Run

**Check 1: Is hook executable?**
```bash
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x
```

**Fix**:
```bash
chmod +x .git/hooks/pre-commit
```

**Check 2: Is hook installed?**
```bash
ls .git/hooks/ | grep pre-commit
```

**Fix**:
```bash
./scripts/install-hooks.sh
```

### Tests Fail in Hook But Pass Manually

**Possible causes**:
1. Environment difference (check PATH)
2. Working directory issue
3. Stale build artifacts

**Debug**:
```bash
# Run hook manually
.git/hooks/pre-commit

# Check hook working directory
cd $(git rev-parse --show-toplevel)
./local-ci.sh --all --quick
```

### Amend Not Working

**Possible causes**:
1. Already pushed to remote
2. Working on wrong branch
3. Multiple commits since the one you want to amend

**Check**:
```bash
# View recent commits
git log --oneline -5

# Check if commit is pushed
git log origin/your-branch..HEAD
```

**Solution**:
- If not pushed: Use `git commit --amend`
- If pushed: Create a fix commit instead
- If multiple commits: Use `git rebase -i` to squash

## Best Practices

### Commit Frequency

**✅ Good**:
- Commit after each Red-Green-Refactor cycle
- Commit when a logical unit of work is complete
- Commit before switching tasks or branches

**❌ Bad**:
- Committing half-implemented features
- Committing broken code
- Waiting too long between commits

### Commit Size

**✅ Good**:
- Small, focused commits
- One logical change per commit
- Test and implementation together

**❌ Bad**:
- Massive commits with multiple unrelated changes
- Mixing features and fixes
- Separate commits for test and implementation

### Commit Messages

**✅ Good**:
```bash
feat: Add currency formatter with symbol support
test: Add comprehensive currency formatter tests
refactor: Simplify currency formatting logic
```

**❌ Bad**:
```bash
Update files
Fix stuff
WIP (on main branch)
Quick fix (without tests)
```

## Summary Checklist

Before every commit, verify:

- [ ] All tests pass (`./local-ci.sh --all --quick`)
- [ ] New code has corresponding tests
- [ ] Tests were written BEFORE implementation
- [ ] No WIP or "fix" commits on main
- [ ] Commit message follows conventions
- [ ] If fixing previous commit, use `--amend` (if not pushed)
- [ ] No `--no-verify` unless truly necessary

---

**Remember**: Clean git history reflects clean code. Take pride in your commits!
