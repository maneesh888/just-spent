# Auto-Merge Workflow Guide

## Complete Development Workflow with Auto-Merge

### Overview

Auto-merge is a **GitHub server-side feature** that automatically merges your PR when all checks pass. You enable it **after creating the PR**, and it executes on **GitHub's servers** (not your laptop).

## Step-by-Step Workflow

### Phase 1: Local Development (Your Laptop)

```bash
# 1. Create feature branch
git checkout -b feature/multi-currency-support

# 2. Make your changes
# ... edit files ...

# 3. Run local CI (optional but recommended)
./local-ci.sh --all --quick
# ✅ Local checks pass

# 4. Commit changes
git add .
git commit -m "feat: Add multi-currency support"

# 5. Push to GitHub
git push origin feature/multi-currency-support
```

**At this point:** Your code is on GitHub, but no PR exists yet.

### Phase 2: Create PR (GitHub)

```bash
# 6. Create PR to develop branch
gh pr create \
  --base develop \
  --title "Add multi-currency support" \
  --body "Implements tabbed UI for multiple currencies"

# Output:
# https://github.com/username/just-spent/pull/42
```

**At this point:** PR exists on GitHub, GitHub Actions start running automatically.

### Phase 3: Enable Auto-Merge (GitHub)

```bash
# 7. Enable auto-merge
gh pr merge --auto --squash

# Output:
# ✓ Pull request #42 will be automatically merged via squash when all requirements are met
```

**At this point:**
- ✅ Auto-merge is enabled
- ✅ GitHub Actions are running (11-12 min)
- ✅ **You can close your laptop and leave!**
- 🤖 GitHub will merge automatically when checks pass

### Phase 4: Automatic Merge (GitHub Servers)

**What happens while you're offline:**

```
Time    Status
────    ──────
0:00    GitHub Actions start
        ├─ Android Build & Test
        └─ iOS Build & Test

5:30    Android tests complete ✅

11:00   iOS tests complete ✅

11:01   🤖 Auto-merge executes
        └─ PR #42 merged to develop

11:02   ✅ Complete!
```

**GitHub sends you notifications:**
- 📧 Email: "PR #42 was automatically merged"
- 🔔 GitHub notification
- 💬 Slack/Discord (if configured)

### Phase 5: Update Local Branch (Your Laptop)

```bash
# 8. Pull merged changes (when you're back)
git checkout develop
git pull origin develop

# 9. Delete feature branch (cleanup)
git branch -d feature/multi-currency-support
git push origin --delete feature/multi-currency-support

# Or use gh cli
gh pr close 42 --delete-branch
```

## Timeline Comparison

### Without Auto-Merge

```
Timeline                            Location    You Must...
────────────────────────────────    ────────    ───────────
0:00  Create PR                     GitHub      Push code
0:01  GitHub Actions start          GitHub      Wait...
11:00 GitHub Actions complete       GitHub      Check status
11:01 ⏳ Waiting for manual merge   GitHub      Click "Merge"
      ... you're busy/sleeping ...
14:00 You come back                 GitHub      Finally merge!
```

**Total time to merge:** 14 hours (with delay)
**Manual steps:** 2 (create PR, merge PR)

### With Auto-Merge

```
Timeline                            Location    You Must...
────────────────────────────────    ────────    ───────────
0:00  Create PR                     GitHub      Push code
0:01  Enable auto-merge             GitHub      One command
0:02  GitHub Actions start          GitHub      (nothing)
      ... you go offline ...
11:00 GitHub Actions complete       GitHub      (nothing)
11:01 🤖 Auto-merge executes         GitHub      (nothing)
```

**Total time to merge:** 11 minutes (no delay)
**Manual steps:** 1 (create PR + enable auto-merge)

## When to Use Auto-Merge

### ✅ Use Auto-Merge For:

- **Feature branches to `develop`** - routine development
- **Bug fixes** - after local CI passes
- **Refactoring** - low-risk changes
- **Documentation updates** - typos, improvements
- **Solo development** - you trust your local CI

### ❌ Don't Use Auto-Merge For:

- **PRs to `main`** - production deserves manual review
- **Breaking changes** - API changes, migrations
- **Security updates** - require careful review
- **First-time features** - want to double-check
- **Team PRs** - when approval discussions are needed

## Multiple PRs Scenario

### What Happens

```
Scenario:
─────────
1. Create PR #1 (feature-a) → develop
2. Enable auto-merge on PR #1
3. Create PR #2 (feature-b) → develop
4. Enable auto-merge on PR #2
```

### Execution Order

```
Time    Event
────    ─────
0:00    PR #1 GitHub Actions start
0:00    PR #2 GitHub Actions start (parallel!)

11:00   PR #1 checks pass ✅
11:01   🤖 PR #1 auto-merges to develop

11:05   PR #2 checks pass ✅
11:05   ⚠️  PR #2 is now STALE (develop changed)
11:05   Auto-merge WAITS (if branch protection enabled)
```

**What you must do:**

```bash
# Option 1: GitHub UI
# Go to PR #2 → Click "Update branch"
# GitHub Actions re-run → Auto-merges when pass

# Option 2: CLI
gh pr view 2  # Check status
# If stale, update branch via UI
```

**With proper branch protection:**
- PR #2 won't auto-merge while stale
- You must manually update the branch
- Then auto-merge continues

## Failure Scenarios

### Scenario 1: Checks Fail

```
Timeline:
─────────
0:00  Create PR + enable auto-merge
11:00 iOS tests fail ❌
11:01 Auto-merge STOPS (doesn't execute)
```

**What you do:**
```bash
# Fix the issue locally
./local-ci.sh --ios  # Test fix

# Push fix
git add .
git commit -m "fix: Resolve iOS test failure"
git push origin feature/my-feature

# GitHub Actions re-run automatically
# Auto-merge will execute when checks pass
```

### Scenario 2: Merge Conflicts

```
Timeline:
─────────
0:00  Create PR + enable auto-merge
5:00  Someone merges another PR to develop
11:00 Your checks pass ✅
11:01 Merge conflict detected ⚠️
11:01 Auto-merge STOPS
```

**What you do:**
```bash
# Resolve conflict locally
git checkout feature/my-feature
git pull origin develop
# ... resolve conflicts ...
git add .
git commit -m "fix: Resolve merge conflicts"
git push origin feature/my-feature

# Auto-merge continues when checks pass
```

## Configuration

### Enable Auto-Merge for Repository

**Settings → General → Pull Requests:**

☑️ Allow auto-merge
☑️ Automatically delete head branches (cleanup)

### Branch Protection (Required)

See `.github/BRANCH_PROTECTION_GUIDE.md` for setup.

**Minimum requirements:**
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Status checks: Android Build & Test, iOS Build & Test

## Commands Reference

### Create PR with Auto-Merge (One-Liner)

```bash
# Create PR and enable auto-merge in one go
gh pr create --base develop --title "My feature" && gh pr merge --auto --squash
```

### Check Auto-Merge Status

```bash
# View PR status
gh pr view 42

# Output shows:
# Auto-merge: Enabled (squash)
# Status: Waiting for checks to pass
```

### Disable Auto-Merge

```bash
# If you change your mind
gh pr merge --disable-auto 42
```

### List PRs with Auto-Merge

```bash
# Show all PRs with auto-merge enabled
gh pr list --json number,title,autoMergeRequest \
  --jq '.[] | select(.autoMergeRequest != null) | {number, title}'
```

## Troubleshooting

### "Auto-merge is not allowed"

**Cause:** Repository settings don't allow auto-merge

**Fix:**
1. Go to Settings → General → Pull Requests
2. Enable "Allow auto-merge"
3. Save changes

### Auto-merge enabled but not merging

**Cause:** Status checks not passing or branch protection requirements not met

**Fix:**
```bash
# Check PR status
gh pr checks 42

# View detailed status
gh pr view 42

# Common issues:
# - Status checks still running (wait)
# - Status checks failed (fix and push)
# - Branch is stale (update branch)
# - Merge conflicts (resolve locally)
```

### Want to merge manually instead

```bash
# Disable auto-merge
gh pr merge --disable-auto 42

# Then merge manually
gh pr merge 42 --squash
```

## Best Practices

### 1. Run Local CI First

```bash
# Always validate locally before pushing
./local-ci.sh --all --quick
git push origin feature/x
```

**Why:** Catch issues early, save GitHub Actions minutes

### 2. Enable Auto-Merge Immediately

```bash
# Right after creating PR
gh pr create ... && gh pr merge --auto --squash
```

**Why:** Don't forget to enable it later

### 3. Monitor Notifications

- Enable GitHub mobile app notifications
- Check email for merge confirmations
- Set up Slack/Discord webhooks (optional)

### 4. Clean Up Branches

```bash
# After auto-merge completes
git checkout develop
git pull
git branch -d feature/x
git push origin --delete feature/x

# Or enable auto-delete in repo settings
```

### 5. Use Squash Merge for Develop

```bash
# Always use --squash for develop
gh pr merge --auto --squash
```

**Why:** Keeps develop history clean

### 6. Keep Main Manual

```bash
# For main branch, always review manually
gh pr create --base main ...
# Review carefully, then:
gh pr merge 42 --squash  # Manual merge
```

## Summary

**Where:** GitHub servers (not your laptop)
**When:** After you create the PR and enable auto-merge
**Duration:** ~11-12 minutes (GitHub Actions runtime)
**Requirement:** All status checks must pass
**Benefit:** Hands-free merging, no need to wait

**Simple workflow:**
```bash
./local-ci.sh --all     # Validate locally
git push origin feature # Push to GitHub
gh pr create --base develop && gh pr merge --auto --squash
# ✅ Done! Go have coffee, GitHub handles the rest
```

---

**Related Documentation:**
- `.github/BRANCH_PROTECTION_GUIDE.md` - Branch protection setup
- `.github/workflows/pr-checks.yml` - CI workflow configuration
- `LOCAL-CI.md` - Local CI usage guide
