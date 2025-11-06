# Quick Git Reference - Just Spent

## Common Workflows

### ✅ Correct: Commit → Find Bug → Amend

```bash
# 1. Make changes and commit
git add .
git commit -m "feat: Add currency formatter"

# 2. Discover bug immediately
# 3. Fix the bug
# 4. Run tests to verify fix
./local-ci.sh --all --quick

# 5. Stage the fixes
git add <fixed-files>

# 6. Amend the commit (clean history)
git commit --amend --no-edit

# If you want to update the message too:
git commit --amend -m "feat: Add currency formatter (fixed edge case)"
```

### ❌ Wrong: Commit → Find Bug → New Fix Commit

```bash
# Don't do this!
git commit -m "feat: Add currency formatter"
git commit -m "fix: Currency formatter bug"  # ❌ Creates messy history
```

### WIP Commits (Feature Branches Only)

```bash
# Save work in progress
git commit -m "WIP: Implementing currency formatter"
# Hook automatically bypasses checks for WIP commits

# Or use --no-verify
git commit --no-verify -m "Saving progress"

# Before creating PR, clean up WIP commits
git rebase -i HEAD~3  # Squash WIP commits
```

### Squashing Multiple Commits

```bash
# You have multiple small commits
git log --oneline -5
# abc123 fix: Another typo
# def456 fix: Typo in comment
# ghi789 feat: Add feature

# Squash them into one
git rebase -i HEAD~3

# In editor, change "pick" to "squash" for commits to merge:
pick ghi789 feat: Add feature
squash def456 fix: Typo in comment
squash abc123 fix: Another typo

# Save and edit the final commit message
```

## Pre-Commit Hook Behavior

### Automatic Checks

The hook runs automatically and:
1. ✅ Validates test coverage for changed files
2. ✅ Runs `./local-ci.sh --all --quick`
3. ✅ Blocks commit if tests fail or coverage missing

### Bypass Methods

**Method 1: WIP prefix (recommended)**
```bash
git commit -m "WIP: Half-done feature"
```

**Method 2: --no-verify flag**
```bash
git commit --no-verify -m "Saving work"
```

**Method 3: Disable hook**
```bash
rm .git/hooks/pre-commit  # Disable
./scripts/install-hooks.sh  # Re-enable
```

## Quick Fixes

### Hook Not Running

```bash
# Make executable
chmod +x .git/hooks/pre-commit

# Reinstall
./scripts/install-hooks.sh
```

### Tests Pass Manually But Fail in Hook

```bash
# Run hook manually to debug
.git/hooks/pre-commit

# Check working directory
cd $(git rev-parse --show-toplevel)
./local-ci.sh --all --quick
```

### Want to Amend But Already Pushed

```bash
# Check if pushed
git log origin/your-branch..HEAD

# If pushed: DON'T AMEND, create fix commit instead
git commit -m "fix: Address issue in previous commit"

# If not pushed: Safe to amend
git commit --amend --no-edit
```

## Commit Message Conventions

```bash
# Feature
git commit -m "feat: Add multi-currency support"

# Bug fix
git commit -m "fix: Currency formatter edge case"

# Tests
git commit -m "test: Add currency formatter tests"

# Refactor
git commit -m "refactor: Simplify formatting logic"

# Documentation
git commit -m "docs: Update git workflow guide"

# Work in progress (bypasses hooks)
git commit -m "WIP: Implementing voice parser"
```

## TDD Workflow Reminder

```bash
# 1. 🔴 RED: Write failing test first
touch ios/JustSpent/JustSpentTests/CurrencyFormatterTests.swift
# Write failing test
xcodebuild test -scheme JustSpent  # Should fail

# 2. 🟢 GREEN: Implement minimal code
# Edit source file
xcodebuild test -scheme JustSpent  # Should pass

# 3. ♻️ REFACTOR: Clean up (keeping tests green)
# Improve code quality
xcodebuild test -scheme JustSpent  # Should still pass

# 4. Commit both test and implementation together
git add JustSpentTests/CurrencyFormatterTests.swift
git add JustSpent/Utils/CurrencyFormatter.swift
git commit -m "feat: Add currency formatter with tests"
```

## Branch-Specific Rules

### Main Branch

- ❌ No direct commits
- ❌ No --no-verify
- ❌ No WIP commits
- ❌ No force push
- ✅ All tests must pass
- ✅ Requires PR review

### Feature Branches

- ✅ WIP commits OK (clean up before PR)
- ✅ Can use --no-verify
- ✅ Amend commits freely before push
- ✅ Force push allowed (carefully)
- ⚠️ Clean up before creating PR

## Quick Commands

```bash
# View recent commits
git log --oneline -10

# Check commit status (pushed or not)
git log origin/main..HEAD

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Amend without changing message
git commit --amend --no-edit

# Amend and update message
git commit --amend -m "new message"

# Check hook status
ls -la .git/hooks/pre-commit

# Run local CI manually
./local-ci.sh --all --quick
```

## Summary

**Golden Rules:**
1. ✅ Always write tests first (TDD)
2. ✅ Use `--amend` for immediate fixes (before push)
3. ✅ Clean up WIP commits before PR
4. ✅ Let pre-commit hook run (don't bypass unless WIP)
5. ❌ Never commit failing tests
6. ❌ Never use --no-verify on main branch
7. ❌ Never amend commits that are pushed
8. ❌ Never create "fix" commits for immediate bugs

**When in Doubt:**
- Run `./local-ci.sh --all --quick` before committing
- Check `docs/GIT-WORKFLOW-RULES.md` for detailed guidance
- Ask yourself: "Is this the cleanest way to structure this commit?"
