# Just Spent - Deployment Checklist & Runbook

## Overview

This document provides step-by-step checklists and runbooks for deploying Just Spent to production. Follow these procedures to ensure smooth, error-free deployments.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Beta Release Runbook](#beta-release-runbook)
3. [Production Release Runbook](#production-release-runbook)
4. [Hotfix Release Runbook](#hotfix-release-runbook)
5. [Rollback Procedures](#rollback-procedures)
6. [Post-Deployment Monitoring](#post-deployment-monitoring)
7. [Emergency Contacts](#emergency-contacts)

---

## Pre-Deployment Checklist

### Code Quality Checks

Before starting any release, verify:

- [ ] **All tests pass**
  ```bash
  ./local-ci.sh --all
  ```

- [ ] **Code coverage ≥85%**
  ```bash
  # Check coverage reports in .ci-results/
  ```

- [ ] **No failing builds in main branch**
  ```bash
  # Check GitHub Actions: https://github.com/YOUR_USERNAME/just-spent/actions
  ```

- [ ] **All PRs merged and reviewed**
  ```bash
  git log origin/main..HEAD  # Should be empty
  ```

### Documentation Checks

- [ ] **Changelog updated** (CHANGELOG.md)
- [ ] **Version number decided** (SemVer format)
- [ ] **Release notes drafted** (for App Store/Play Store)
- [ ] **Screenshots updated** (if UI changed)
- [ ] **Privacy policy current** (if data handling changed)

### Dependency Checks

- [ ] **All dependencies up to date**
  ```bash
  # iOS
  cd ios && pod outdated

  # Android
  cd android && ./gradlew dependencyUpdates
  ```

- [ ] **No critical security vulnerabilities**
  ```bash
  # Check dependency security advisories
  ```

### Environment Checks

- [ ] **Secrets configured in GitHub**
  - All 12 secrets present
  - No expired certificates
  - Service account access valid

- [ ] **API endpoints configured correctly**
  - Production URLs set
  - Environment variables correct

- [ ] **Third-party services operational**
  - Backend API healthy
  - Analytics services running
  - Crash reporting configured

### Compliance Checks

- [ ] **App Store guidelines compliance** (iOS)
  - No rejected features
  - Privacy manifest up to date
  - Age rating appropriate

- [ ] **Google Play policies compliance** (Android)
  - Data safety section filled
  - Target API level current
  - Permissions justified

---

## Beta Release Runbook

### Objective
Deploy a beta version to TestFlight (iOS) and Internal Testing (Android) for QA and early feedback.

### Timeline
Estimated time: 2-4 hours (including testing)

### Prerequisites

- [ ] Pre-deployment checklist complete
- [ ] QA team notified of upcoming beta
- [ ] Beta testers list updated

### Step 1: Prepare Release Branch

```bash
# Ensure you're on latest main
git checkout main
git pull origin main

# Verify working directory is clean
git status
```

**Expected output:** `nothing to commit, working tree clean`

### Step 2: Bump Version

```bash
# For first beta of version 1.2.0
./scripts/bump-version.sh 1.2.0-beta.1

# For subsequent betas
./scripts/bump-version.sh 1.2.0-beta.2
```

**Verify changes:**
```bash
git diff ios/JustSpent/JustSpent/Info.plist
git diff android/app/build.gradle
```

### Step 3: Update Changelog

Edit `CHANGELOG.md`:

```markdown
## [1.2.0-beta.1] - 2025-01-30

### Added
- Multi-currency support with tabbed interface
- Voice command improvements

### Fixed
- Currency formatting consistency
- Empty state display issues

### Changed
- Updated onboarding flow
```

### Step 4: Commit and Tag

```bash
# Commit version bump
git add .
git commit -m "chore: Release v1.2.0-beta.1"

# Create git tag
git tag -a v1.2.0-beta.1 -m "Beta release v1.2.0-beta.1"

# Push to remote
git push origin main
git push origin v1.2.0-beta.1
```

**Verification:**
- Tag appears on GitHub: https://github.com/YOUR_USERNAME/just-spent/tags

### Step 5: Monitor Deployment

```bash
# Watch GitHub Actions
# Go to: https://github.com/YOUR_USERNAME/just-spent/actions

# Monitor both workflows:
# 1. Deploy iOS to TestFlight
# 2. Deploy Android to Play Store
```

**iOS Deployment Timeline:**
- Checkout: ~1 min
- Build: ~5-8 min
- Upload to TestFlight: ~2-3 min
- **Total: ~10-15 min**

**Android Deployment Timeline:**
- Checkout: ~1 min
- Build: ~3-5 min
- Upload to Play Store: ~1-2 min
- **Total: ~5-10 min**

### Step 6: Verify Builds

**iOS (TestFlight):**
```
1. Go to: https://appstoreconnect.apple.com/
2. Navigate to: Just Spent → TestFlight
3. Verify new build appears in "iOS Builds"
4. Check processing status (may take 10-30 min)
5. Once processed, add to "Internal Testing" group
```

**Android (Play Console):**
```
1. Go to: https://play.google.com/console/
2. Navigate to: Just Spent → Release → Internal testing
3. Verify new release appears
4. Check "Review summary" for any warnings
5. Confirm rollout status
```

### Step 7: Notify QA Team

Send notification to QA team:

```
Subject: Beta v1.2.0-beta.1 Available for Testing

Hi Team,

New beta build is now available:

iOS: TestFlight (build processing, ~30 min)
Android: Play Store Internal Testing (available now)

Version: 1.2.0-beta.1
Changes: See CHANGELOG.md

Testing focus areas:
- Multi-currency support
- Voice commands
- Onboarding flow

Please report any issues in Jira.

Thanks!
```

### Step 8: QA Testing

**QA Checklist:**
- [ ] App installs successfully
- [ ] Onboarding flow works
- [ ] Voice commands functional
- [ ] Multi-currency switching works
- [ ] No crashes on startup
- [ ] Performance acceptable
- [ ] UI rendering correct

**Timeline:** 24-48 hours for QA feedback

### Step 9: Address Feedback

If issues found:

```bash
# Fix bugs on main branch
git checkout main
# ... fix bugs, run tests ...
git commit -am "fix: Address beta feedback"
git push

# Release next beta
./scripts/bump-version.sh 1.2.0-beta.2
git commit -am "chore: Release v1.2.0-beta.2"
git tag v1.2.0-beta.2
git push && git push --tags
```

### Step 10: Beta Approval

Once QA approves:

- [ ] All critical bugs fixed
- [ ] Performance meets targets
- [ ] No crashes in testing
- [ ] Ready for production

**Decision:** Proceed to production release

---

## Production Release Runbook

### Objective
Deploy a production-ready version to App Store (iOS) and Play Store Production (Android).

### Timeline
Estimated time: 3-5 days (including review times)

### Prerequisites

- [ ] Beta testing complete with approval
- [ ] All critical bugs fixed
- [ ] Release notes finalized
- [ ] Screenshots and metadata updated
- [ ] Marketing team notified

### Step 1: Prepare Production Release

```bash
# Ensure you're on latest main with all beta fixes
git checkout main
git pull origin main
```

### Step 2: Bump to Production Version

```bash
# Remove beta suffix
./scripts/bump-version.sh 1.2.0
```

### Step 3: Final Testing

```bash
# Run full test suite one more time
./local-ci.sh --all

# Verify no failures
```

### Step 4: Update App Store/Play Store Metadata

**iOS (App Store Connect):**
```
1. Go to: https://appstoreconnect.apple.com/
2. Navigate to: Just Spent → [Version 1.2.0]
3. Fill in:
   - What's New in This Version (release notes)
   - Description (if changed)
   - Keywords (if changed)
   - Support URL
   - Marketing URL
   - Screenshots (if changed)
4. Save changes
```

**Android (Play Console):**
```
1. Go to: https://play.google.com/console/
2. Navigate to: Just Spent → Store presence → Main store listing
3. Update:
   - Short description
   - Full description
   - What's new (release notes)
   - Screenshots (if changed)
4. Save changes
```

### Step 5: Commit and Tag Production Release

```bash
# Commit version bump
git add .
git commit -m "chore: Release v1.2.0"

# Create git tag
git tag -a v1.2.0 -m "Production release v1.2.0"

# Push to remote
git push origin main
git push origin v1.2.0
```

### Step 6: Monitor Deployment

Watch GitHub Actions (same as beta)

### Step 7: Submit for Review

**iOS:**
```
Option A: Automatic submission (configured in Fastlane)
  - GitHub Actions will submit for review automatically
  - Check status in App Store Connect

Option B: Manual submission
  1. Go to App Store Connect
  2. Navigate to: Just Spent → [Version 1.2.0]
  3. Click "Add for Review"
  4. Answer export compliance questions
  5. Submit
```

**Android:**
```
Option A: Automatic rollout (configured in Fastlane)
  - GitHub Actions will start 10% rollout
  - Monitor in Play Console

Option B: Manual rollout
  1. Go to Play Console
  2. Navigate to: Just Spent → Production
  3. Click "Promote release" from Beta
  4. Set rollout to 10%
  5. Confirm
```

### Step 8: App Review Wait Period

**iOS Review Timeline:**
- Typical: 24-48 hours
- Range: 1 hour - 7 days
- Check status: https://appstoreconnect.apple.com/

**Android Review Timeline:**
- Typical: Instant - 2 hours
- Range: Instant - 7 days (rare)
- Check status: https://play.google.com/console/

### Step 9: Handle Review Issues

**If iOS Review is Rejected:**

```
1. Read rejection reason carefully
2. Fix issues in code
3. Bump version: ./scripts/bump-version.sh 1.2.1
4. Resubmit following steps 5-6
```

**If Android Review has warnings:**

```
1. Address warnings in Play Console
2. Update metadata if needed
3. Rollout will proceed after addressing
```

### Step 10: Monitor Initial Rollout (Android)

**Day 1: 10% Rollout**

Monitor metrics:
- Crash-free rate (target: ≥99%)
- ANR rate (target: <0.5%)
- User ratings (target: ≥4.0)
- Install success rate (target: ≥95%)

```bash
# If metrics are good, increase rollout
# Manually trigger GitHub Actions workflow with:
# - Track: production
# - Rollout: 0.5 (50%)
```

**Day 2: 50% Rollout**

Continue monitoring metrics

**Day 3: 100% Rollout**

```bash
# Complete rollout if all metrics stable
# Trigger workflow with:
# - Track: production
# - Rollout: 1.0 (100%)
```

### Step 11: Announce Release

**Internal Announcement:**
```
Subject: Just Spent v1.2.0 Released to Production

Team,

Version 1.2.0 is now live:

iOS: Approved and released
Android: 100% rollout complete

Key features:
- Multi-currency support
- Improved voice commands

Monitoring dashboard: [link]

Great work everyone!
```

**Public Announcement:**
- Social media posts
- Blog post
- Email to users (if applicable)

---

## Hotfix Release Runbook

### Objective
Deploy an urgent fix to production as quickly as possible.

### When to Use
- Critical bug affecting users
- Security vulnerability
- Data loss issue
- App crash on launch

### Timeline
Estimated time: 1-3 hours (fast track)

### Step 1: Create Hotfix Branch

```bash
# Branch from main (or latest production tag)
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug
```

### Step 2: Implement Fix

```bash
# Write test that reproduces bug (TDD)
# Implement fix
# Verify test passes

./local-ci.sh --all --quick
```

### Step 3: Bump Patch Version

```bash
# If current version is 1.2.0, bump to 1.2.1
./scripts/bump-version.sh 1.2.1
```

### Step 4: Commit and Tag

```bash
git add .
git commit -m "fix: Critical bug affecting user data"
git checkout main
git merge hotfix/critical-bug --no-ff
git tag -a v1.2.1 -m "Hotfix v1.2.1"
git push origin main
git push origin v1.2.1
```

### Step 5: Fast-Track Deployment

**iOS:**
```
- Deploy to TestFlight (automatic via GitHub Actions)
- Test quickly (30 min)
- Submit to App Store with "Critical Bug Fix" in review notes
- Request expedited review in App Store Connect
```

**Android:**
```
- Deploy to Internal Testing (automatic)
- Test quickly (15 min)
- Promote to Production with 100% rollout immediately
  (no phased rollout for critical fixes)
```

### Step 6: Monitor Closely

- Watch crash reports in real-time
- Monitor user ratings/reviews
- Check support tickets
- Be ready to rollback if needed

### Step 7: Merge to Develop

```bash
# Ensure hotfix is in develop branch too
git checkout develop
git merge main
git push origin develop
```

---

## Rollback Procedures

### When to Rollback

Immediate rollback if:
- Crash rate >1%
- Critical feature completely broken
- Data corruption occurring
- Security breach detected

### iOS Rollback Procedure

**Option 1: Disable New Version**

```
1. Go to App Store Connect
2. Navigate to: Just Spent → App Store → [Problematic Version]
3. Click "Remove from Sale"
4. Users can't download new version
5. Existing users keep current version
```

**Limitation:** Can't force users back to old version

**Option 2: Emergency Release (Recommended)**

```bash
# Release previous version with bumped version number
git checkout v1.1.0  # Last known good version
./scripts/bump-version.sh 1.2.2
git commit -am "chore: Emergency rollback to stable version"
git tag v1.2.2
git push origin main
git push origin v1.2.2

# Request expedited review
```

### Android Rollback Procedure

**Option 1: Halt Rollout**

```
1. Go to Play Console
2. Navigate to: Just Spent → Production
3. Click "Halt rollout"
4. No new users get the broken version
5. Existing users keep their version
```

**Option 2: Rollback to Previous Release**

```
1. Go to Play Console
2. Navigate to: Just Spent → Production
3. Find previous release in "Releases" tab
4. Click "Rollback" on old release
5. All users get downgraded within hours
```

### Communication During Rollback

**Internal:**
```
URGENT: Rollback Initiated

Version 1.2.0 rolled back due to [ISSUE]

Action taken:
- iOS: [action]
- Android: [action]

Current status: Monitoring

Incident channel: #incident-v120
```

**External (if needed):**
```
We're aware of an issue in the latest update and are
working on a fix. If you're experiencing problems,
please update to the latest version when available.
We apologize for the inconvenience.
```

---

## Post-Deployment Monitoring

### First 24 Hours

Monitor these metrics closely:

**Crash Reports:**
```
iOS: https://appstoreconnect.apple.com/ → Analytics → Crashes
Android: https://play.google.com/console/ → Vitals → Crashes
```

Target: Crash-free rate ≥99.5%

**Performance:**
```
- App launch time
- API response times
- Voice command processing speed
```

Target: No degradation from previous version

**User Feedback:**
```
iOS: App Store reviews
Android: Play Store reviews
```

Monitor for:
- New 1-star reviews mentioning bugs
- Common complaints
- Crash reports in reviews

**Usage Metrics:**
```
- DAU (Daily Active Users)
- Session length
- Voice command usage
- Feature adoption (multi-currency)
```

### First Week

**Monday (Day 1):**
- Check initial metrics
- Increase Android rollout to 50% (if stable)

**Wednesday (Day 3):**
- Review accumulated data
- Increase Android rollout to 100%
- Check for any emerging patterns

**Friday (Day 5):**
- Weekly metrics review
- Plan next sprint/fixes

### Monitoring Tools

**Crash Reporting:**
- Firebase Crashlytics
- App Store Connect
- Play Console Vitals

**Analytics:**
- Firebase Analytics
- Custom analytics dashboard

**User Feedback:**
- App Store Connect reviews
- Play Console reviews
- Support ticket system

**Alerts to Configure:**

```yaml
Crash Rate Alert:
  condition: crash_free_rate < 99%
  action: Notify on-call engineer

ANR Alert:
  condition: anr_rate > 0.5%
  action: Investigate immediately

Rating Alert:
  condition: avg_rating < 4.0
  action: Review recent reviews

Performance Alert:
  condition: app_launch_time > 3s
  action: Profile performance
```

---

## Emergency Contacts

### On-Call Rotation

**Week of 2025-01-27:**
- Primary: [Name] - [Phone] - [Email]
- Secondary: [Name] - [Phone] - [Email]

### Escalation Path

1. **On-Call Engineer** (responds within 15 min)
2. **Engineering Lead** (responds within 30 min)
3. **CTO** (responds within 1 hour)

### External Contacts

**Apple:**
- Developer Support: https://developer.apple.com/contact/
- Expedited Review Request: Via App Store Connect

**Google:**
- Developer Support: https://support.google.com/googleplay/android-developer/
- Policy Appeals: Via Play Console

### Communication Channels

- **Slack:** #incidents, #deployments
- **Email:** team@justspent.com
- **Phone:** Emergency hotline (for critical issues)

---

## Deployment Schedule

### Regular Release Cadence

**Sprint Length:** 2 weeks

**Release Schedule:**
- **Week 1:** Development
- **Week 2 Monday:** Feature freeze, beta release
- **Week 2 Wed-Thu:** QA testing
- **Week 2 Friday:** Production release (if QA approved)

**Holiday Blackout Periods:**
- No production releases:
  - December 20 - January 5
  - Week before/after major holidays

---

## Checklist Summary

### Before Every Release

- [ ] All tests pass
- [ ] Changelog updated
- [ ] Version bumped
- [ ] Git tag created
- [ ] Secrets valid
- [ ] Compliance checked

### Beta Release

- [ ] QA team notified
- [ ] Beta testers updated
- [ ] TestFlight build uploaded
- [ ] Play Console internal testing updated
- [ ] Feedback collected
- [ ] Issues addressed

### Production Release

- [ ] Beta testing complete
- [ ] Metadata updated
- [ ] Reviews submitted
- [ ] Rollout monitored
- [ ] Metrics stable
- [ ] Team notified

### Hotfix Release

- [ ] Bug verified
- [ ] Fix tested
- [ ] Expedited review requested
- [ ] Rollout fast-tracked
- [ ] Monitoring intensive
- [ ] Postmortem scheduled

---

**Last Updated:** 2025-01-29
**Maintained By:** Development Team
**Related Docs:** `DEPLOYMENT-GUIDE.md`, `SECRETS-SETUP-GUIDE.md`
