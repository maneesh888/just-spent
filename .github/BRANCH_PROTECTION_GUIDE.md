# GitHub Branch Protection Setup Guide

## Purpose
Prevent stale PRs from being merged when the base branch (develop/main) has been updated by other PRs.

## Problem Scenario
```
1. PR #1 → develop: Passes checks ✅
2. PR #2 → develop: Passes checks ✅
3. Merge PR #1 → develop is now updated
4. PR #2 still shows ✅ but hasn't been tested against new develop
5. Merging PR #2 might break develop!
```

## Solution: Branch Protection Rules

### For `develop` Branch

1. **Go to Repository Settings**
   - GitHub.com → Your Repository → Settings → Branches

2. **Add Branch Protection Rule**
   - Click "Add rule"
   - Branch name pattern: `develop`

3. **Enable Required Settings**

   ☑️ **Require a pull request before merging**
   - Required approvals: 0 (solo dev) or 1+ (team)

   ☑️ **Require status checks to pass before merging**
   - Click "Add checks"
   - Select: `Android Build & Test` and `iOS Build & Test`

   ☑️ **Require branches to be up to date before merging** ⭐ KEY SETTING
   - This forces PR branches to be updated before merge
   - Automatically triggers new CI run when you click "Update branch"

   ☑️ **Require conversation resolution before merging** (optional)
   - Good practice for team development

   ☑️ **Do not allow bypassing the above settings** (recommended)
   - Prevents accidentally force-merging

4. **Save Changes**

### For `main` Branch

Follow same steps but with stricter rules:

1. **Branch name pattern**: `main`
2. **Required approvals**: 1+ (even for solo, good habit)
3. **Same status checks**: Android + iOS
4. **Require branches to be up to date**: ✅
5. **Include administrators**: ✅ (enforce on yourself too)

## How It Works

### Before Protection
```
PR #1 → develop (passes) → merge
PR #2 → develop (stale ✅) → can merge ⚠️ DANGEROUS!
```

### After Protection
```
PR #1 → develop (passes) → merge
PR #2 → develop (stale ✅) → "Branch is out of date" ⚠️
         ↓
Click "Update branch" → Merges develop into PR #2
         ↓
GitHub Actions re-runs → New ✅ or ❌
         ↓
Only now can you merge safely
```

## Workflow After Enabling

### When Merging Multiple PRs

1. **Create PR #1 to develop**
   - CI runs → ✅
   - Merge when ready

2. **Create PR #2 to develop**
   - CI runs → ✅

3. **After merging PR #1:**
   - PR #2 shows: "This branch is out-of-date with the base branch"
   - "Merge pull request" button is DISABLED
   - Click "Update branch" button
   - GitHub Actions re-runs automatically
   - Wait for new ✅
   - Now you can merge

### Visual Indicator

When PR is outdated, GitHub shows:
```
⚠️ This branch is out-of-date with the base branch
   Merge the latest changes from develop into this branch.

   [Update branch] button
```

## Local Development Impact

**No impact!** Branch protection only affects merging on GitHub.

You can still:
- ✅ Push to feature branches
- ✅ Run local CI (`./local-ci.sh`)
- ✅ Create PRs
- ✅ Update your branch manually: `git merge develop`

## Benefits

✅ **Prevents Breaking develop**: Stale PRs can't be merged
✅ **Automated Re-testing**: Update branch → CI runs automatically
✅ **Clear Status**: Visual indicator when branch is outdated
✅ **Best Practice**: Industry-standard safety measure
✅ **Works with Concurrency**: Your existing cancellation settings still apply

## Cost Considerations

**GitHub Actions Minutes:**
- Extra CI run when updating branch: ~11-12 minutes
- For solo dev: Usually fine within free tier (2000 min/month)
- For teams: Plan accordingly

**Tip**: Use local CI (`./local-ci.sh`) to validate before pushing, minimizing GitHub Actions usage.

## Testing the Setup

1. **Create two test PRs to develop:**
   ```bash
   git checkout -b test-pr-1
   echo "test 1" >> test1.txt
   git add . && git commit -m "test: PR 1"
   git push origin test-pr-1

   git checkout develop
   git checkout -b test-pr-2
   echo "test 2" >> test2.txt
   git add . && git commit -m "test: PR 2"
   git push origin test-pr-2
   ```

2. **Create PRs on GitHub** for both branches

3. **Merge test-pr-1**

4. **Check test-pr-2**:
   - Should show "out-of-date" warning
   - "Merge" button should be disabled
   - Click "Update branch"
   - CI should re-run
   - Only then can you merge

5. **Clean up**:
   ```bash
   git checkout develop
   git pull
   git branch -D test-pr-1 test-pr-2
   git push origin --delete test-pr-1 test-pr-2
   ```

## Troubleshooting

### "Merge" button still enabled for stale PR

**Cause**: Branch protection not configured correctly

**Fix**:
- Ensure "Require branches to be up to date before merging" is checked
- Ensure status checks are selected
- Save and refresh page

### Update button doesn't trigger CI

**Cause**: Workflow not triggered on `pull_request` type `synchronize`

**Fix**: Your workflow already has this (line 9 in pr-checks.yml), should work

### Can't merge even when up-to-date

**Cause**: Status checks not passing or wrong check names selected

**Fix**:
- Verify check names match: "Android Build & Test", "iOS Build & Test"
- Ensure CI passed successfully (all green ✅)

## Alternative: Manual Process (Not Recommended)

If you don't want branch protection:

1. **Before merging any PR**, check if other PRs are open
2. **After merging**, manually go to other PRs
3. **Click "Checks" tab → "Re-run all jobs"**
4. **Wait for CI** to pass
5. **Then merge**

**Problem**: Easy to forget, no enforcement, error-prone

## Recommendation

**Enable branch protection for both `develop` and `main`.**

Your current workflow is already optimized with:
- ✅ Concurrency cancellation (line 16-18)
- ✅ Efficient parallel jobs (line 21-30)
- ✅ Clear status summary (line 33-39)

Adding branch protection completes the safety net!

---

**Related Documentation:**
- `.github/workflows/pr-checks.yml` - Workflow configuration
- `LOCAL-CI.md` - Hybrid CI/CD approach
- [GitHub Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
