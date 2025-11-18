# Just Spent - Deployment Documentation

## 🚀 Overview

This directory contains complete documentation for deploying Just Spent to Apple App Store and Google Play Store using **fully automated continuous deployment (CD)**.

## 📚 Documentation Index

### 1. **DEPLOYMENT-GUIDE.md** - Start Here!
**What:** Complete guide to CD concepts, architecture, and implementation
**When to read:** Before setting up deployment for the first time
**Key topics:**
- What is continuous deployment
- Mobile app deployment architecture
- iOS deployment pipeline (TestFlight → App Store)
- Android deployment pipeline (Internal → Beta → Production)
- Version management with SemVer
- Environment configuration
- Phased rollouts and monitoring

[Read DEPLOYMENT-GUIDE.md →](./DEPLOYMENT-GUIDE.md)

### 2. **SECRETS-SETUP-GUIDE.md** - Configuration Reference
**What:** Step-by-step guide to setting up all required secrets and credentials
**When to read:** When configuring deployment for the first time
**Key topics:**
- Apple Developer Account setup
- Google Play Developer Account setup
- Generating iOS distribution certificates
- Creating Android keystores
- Service account configuration
- GitHub secrets management
- Testing your setup

[Read SECRETS-SETUP-GUIDE.md →](./SECRETS-SETUP-GUIDE.md)

### 3. **DEPLOYMENT-CHECKLIST.md** - Operational Runbooks
**What:** Detailed checklists and runbooks for each deployment scenario
**When to read:** Before every deployment
**Key topics:**
- Pre-deployment checklist
- Beta release runbook
- Production release runbook
- Hotfix release runbook
- Rollback procedures
- Post-deployment monitoring

[Read DEPLOYMENT-CHECKLIST.md →](./DEPLOYMENT-CHECKLIST.md)

## 🎯 Quick Start

### For First-Time Setup (Estimated time: 4-6 hours)

```bash
# Step 1: Read the deployment guide
cat docs/DEPLOYMENT-GUIDE.md

# Step 2: Setup Apple and Google developer accounts
# Follow: SECRETS-SETUP-GUIDE.md → Prerequisites

# Step 3: Generate certificates and keystores
# Follow: SECRETS-SETUP-GUIDE.md → iOS Secrets Setup
# Follow: SECRETS-SETUP-GUIDE.md → Android Secrets Setup

# Step 4: Configure GitHub secrets
# Follow: SECRETS-SETUP-GUIDE.md → GitHub Secrets Configuration

# Step 5: Test deployment with a test release
./scripts/bump-version.sh 0.0.1-test
git commit -am "chore: Test deployment setup"
git tag v0.0.1-test
git push --tags

# Step 6: Monitor GitHub Actions
# Go to: https://github.com/YOUR_USERNAME/just-spent/actions

# Step 7: Verify builds in app stores
# iOS: https://appstoreconnect.apple.com/
# Android: https://play.google.com/console/

# Step 8: Clean up test release
git tag -d v0.0.1-test
git push --delete origin v0.0.1-test
```

### For Regular Deployments

**Beta Release:**
```bash
# 1. Complete pre-deployment checklist
cat docs/DEPLOYMENT-CHECKLIST.md  # Read "Pre-Deployment Checklist"

# 2. Bump version
./scripts/bump-version.sh 1.2.0-beta.1

# 3. Commit and tag
git commit -am "chore: Beta release v1.2.0-beta.1"
git tag v1.2.0-beta.1
git push && git push --tags

# 4. Monitor deployment (automatic via GitHub Actions)
# Watch: https://github.com/YOUR_USERNAME/just-spent/actions

# 5. Test beta build
# iOS: TestFlight
# Android: Play Console Internal Testing

# 6. Collect feedback and iterate
```

**Production Release:**
```bash
# 1. Complete beta testing
# Follow: DEPLOYMENT-CHECKLIST.md → Production Release Runbook

# 2. Bump to production version
./scripts/bump-version.sh 1.2.0

# 3. Commit and tag
git commit -am "chore: Release v1.2.0"
git tag v1.2.0
git push && git push --tags

# 4. Monitor deployment and app review
# iOS: 24-48 hours review time
# Android: Instant - 2 hours review time

# 5. Monitor rollout (Android)
# Day 1: 10% → Day 2: 50% → Day 3: 100%
```

**Hotfix Release:**
```bash
# 1. Create hotfix branch
git checkout -b hotfix/critical-bug

# 2. Fix bug with tests
# ... implement fix ...
./local-ci.sh --all --quick

# 3. Bump patch version
./scripts/bump-version.sh 1.2.1

# 4. Merge and tag
git checkout main
git merge hotfix/critical-bug
git tag v1.2.1
git push && git push --tags

# 5. Monitor closely and be ready to rollback
```

## 🏗️ Deployment Architecture

### File Structure

```
just-spent/
├── .github/workflows/
│   ├── deploy-ios.yml          # iOS deployment workflow
│   └── deploy-android.yml      # Android deployment workflow
├── ios/
│   ├── fastlane/
│   │   └── Fastfile            # iOS deployment automation
│   └── Gemfile                 # Ruby dependencies
├── android/
│   ├── fastlane/
│   │   └── Fastfile            # Android deployment automation
│   └── Gemfile                 # Ruby dependencies
├── scripts/
│   └── bump-version.sh         # Version management script
└── docs/
    ├── DEPLOYMENT-GUIDE.md     # Complete deployment guide
    ├── SECRETS-SETUP-GUIDE.md  # Secrets configuration
    ├── DEPLOYMENT-CHECKLIST.md # Operational runbooks
    └── DEPLOYMENT-README.md    # This file
```

### Deployment Flow

```
Developer → Git Push → GitHub Actions → App Store Distribution

1. Developer tags release: git tag v1.0.0 && git push --tags
2. GitHub Actions triggered automatically
3. Parallel workflows:
   - iOS: Build → Sign → Test → TestFlight → App Store
   - Android: Build → Sign → Test → Play Console → Rollout
4. Automatic deployment to beta/production
5. Monitoring and rollout management
```

## 🔑 Required Secrets

### iOS Secrets (7)
- `IOS_CERTIFICATES_P12` - Distribution certificate
- `IOS_CERTIFICATES_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE` - App Store provisioning profile
- `APPLE_ID` - Your Apple ID
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- `APPLE_TEAM_ID` - Team ID
- `KEYCHAIN_PASSWORD` - CI keychain password

### Android Secrets (5)
- `ANDROID_KEYSTORE_BASE64` - Upload keystore
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password
- `PLAY_STORE_JSON_KEY` - Service account JSON

**Setup:** See [SECRETS-SETUP-GUIDE.md](./SECRETS-SETUP-GUIDE.md)

## 📊 Deployment Tracks

### iOS (via App Store Connect)

1. **TestFlight Internal** (Automatic)
   - Team members only
   - Instant deployment
   - No review required

2. **TestFlight External** (Manual promotion)
   - Up to 10,000 beta testers
   - App Review required (24-48 hours)
   - Feedback collection

3. **App Store** (Manual submission)
   - Public production release
   - Full App Review required
   - Phased release option available

### Android (via Google Play Console)

1. **Internal Testing** (Automatic)
   - Up to 100 testers
   - Instant deployment
   - No review required

2. **Closed Testing (Beta)** (Manual promotion)
   - Unlimited testers (invite-only)
   - Feedback collection
   - No review typically

3. **Open Testing (Beta)** (Manual promotion)
   - Public beta
   - Anyone can join
   - Gradual rollout option

4. **Production** (Manual promotion or automatic)
   - All users
   - Phased rollout: 10% → 50% → 100%
   - Can halt/rollback anytime

## 🔄 Version Management

### Semantic Versioning (SemVer)

Format: `MAJOR.MINOR.PATCH[-PRERELEASE]`

- **MAJOR:** Breaking changes (1.0.0 → 2.0.0)
- **MINOR:** New features (1.0.0 → 1.1.0)
- **PATCH:** Bug fixes (1.0.0 → 1.0.1)
- **PRERELEASE:** beta.1, rc.1 (1.0.0-beta.1)

### Version Bump Script

```bash
# Usage
./scripts/bump-version.sh <version>

# Examples
./scripts/bump-version.sh 1.2.3          # Release
./scripts/bump-version.sh 1.2.3-beta.1   # Beta
./scripts/bump-version.sh 1.2.3-rc.1     # Release candidate

# What it does:
# - Updates iOS Info.plist (version + build number)
# - Updates Android build.gradle (versionName + versionCode)
# - Updates package.json (if exists)
# - Shows git workflow next steps
```

### Build Number Auto-Increment

- **iOS:** Timestamp-based (YYYYMMDDHHMM)
- **Android:** Timestamp-based (YYMMDDHHMM)
- **Automatic:** Handled by scripts/Fastlane

## 🚨 Emergency Procedures

### Rollback

**iOS:**
```
1. Remove from sale in App Store Connect
2. Release emergency version (previous + bumped version)
3. Request expedited review
```

**Android:**
```
1. Halt rollout in Play Console
2. OR rollback to previous release (automatic downgrade)
3. Monitor user impact
```

### Hotfix

```bash
# Quick hotfix procedure
git checkout -b hotfix/critical
# ... fix bug ...
./scripts/bump-version.sh 1.2.1
git checkout main && git merge hotfix/critical
git tag v1.2.1 && git push --tags
# Monitor closely!
```

**Timeline:** 1-3 hours (vs. 3-5 days for regular release)

## 📈 Monitoring Checklist

### First 24 Hours
- [ ] Crash-free rate ≥99.5%
- [ ] No spike in 1-star reviews
- [ ] Performance metrics stable
- [ ] No critical bugs reported

### First Week
- [ ] Day 1: 10% rollout (Android)
- [ ] Day 3: 50% rollout (Android)
- [ ] Day 5: 100% rollout (Android)
- [ ] Weekly metrics review

### Metrics to Watch
- Crash reports (App Store Connect, Play Console)
- User ratings and reviews
- DAU (Daily Active Users)
- Session length
- Feature adoption rates

## 🎓 Learning Path

### Beginner (Never deployed before)
1. Read: [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) - Complete guide
2. Watch: GitHub Actions in action (after setup)
3. Practice: Test deployment with v0.0.1-test
4. Deploy: First beta release
5. Monitor: TestFlight and Play Console

### Intermediate (Deployed a few times)
1. Read: [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md) - Runbooks
2. Practice: Beta → Production flow
3. Learn: Phased rollouts and monitoring
4. Optimize: Automation and workflows

### Advanced (Regular deployments)
1. Customize: Fastlane lanes for your needs
2. Monitor: Setup alerts and dashboards
3. Optimize: Release cadence and testing
4. Mentor: Help team members with deployments

## 🆘 Getting Help

### Common Issues

**"Secrets not found"**
- Check: [SECRETS-SETUP-GUIDE.md](./SECRETS-SETUP-GUIDE.md) → GitHub Secrets Configuration
- Verify: Secret names match exactly (case-sensitive)

**"Certificate expired"**
- Check: Certificate validity in Apple Developer Portal
- Regenerate: Follow iOS Secrets Setup guide

**"Build failed"**
- Check: GitHub Actions logs
- Run locally: `./local-ci.sh --all`
- Review: Pre-deployment checklist

**"App review rejected"**
- Read: Rejection reason carefully
- Fix: Issues mentioned
- Resubmit: Bump patch version

### Resources

- **Fastlane Docs:** https://docs.fastlane.tools/
- **App Store Connect:** https://appstoreconnect.apple.com/
- **Play Console:** https://play.google.com/console/
- **GitHub Actions:** https://github.com/YOUR_USERNAME/just-spent/actions

### Support Channels

- **Documentation:** This directory
- **Issues:** GitHub Issues
- **Team:** #deployments Slack channel
- **On-Call:** See DEPLOYMENT-CHECKLIST.md → Emergency Contacts

## 📝 Best Practices

### DO:
- ✅ Follow the checklists every time
- ✅ Test beta builds thoroughly
- ✅ Monitor metrics after deployment
- ✅ Use phased rollouts for Android
- ✅ Keep secrets rotated (every 90 days)
- ✅ Maintain changelog

### DON'T:
- ❌ Skip testing before production
- ❌ Deploy on Fridays or holidays
- ❌ Commit secrets to git
- ❌ Ignore crash reports
- ❌ Rush deployments
- ❌ Skip rollback if needed

## 🗓️ Release Schedule

### Regular Cadence
- **Sprint:** 2 weeks
- **Beta:** Week 2, Monday
- **Production:** Week 2, Friday (if QA approved)

### Blackout Periods
- December 20 - January 5
- Week before/after major holidays

## 📊 Success Metrics

### Deployment Quality
- Build success rate: ≥95%
- Deployment time: <15 min (iOS), <10 min (Android)
- Rollback rate: <5%

### App Quality
- Crash-free rate: ≥99.5%
- ANR rate: <0.5%
- App Store rating: ≥4.5
- Play Store rating: ≥4.5

### Process Efficiency
- Time to production: <5 days (from feature complete)
- Hotfix time: <3 hours
- Review approval rate: ≥90%

## 🎉 Summary

You now have:

✅ **Complete CD pipeline** - Fully automated deployments
✅ **iOS workflow** - TestFlight → App Store
✅ **Android workflow** - Internal → Beta → Production
✅ **Version management** - Automated version bumping
✅ **Secrets management** - Secure credential handling
✅ **Operational runbooks** - Step-by-step procedures
✅ **Monitoring strategy** - Post-deployment tracking
✅ **Emergency procedures** - Rollback and hotfix processes

## 🚀 Ready to Deploy?

1. **First-time setup:** Follow [SECRETS-SETUP-GUIDE.md](./SECRETS-SETUP-GUIDE.md)
2. **Regular deployments:** Use [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md)
3. **Questions:** Read [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)

**Happy deploying! 🎉**

---

## ⚠️ Current Status & Known Issues (November 2025)

### iOS Deployment - On Hold

**Issue:** Project uses **Xcode 26.0** (beta) which is not available on GitHub Actions runners.

**GitHub Actions Xcode Support:**
- Maximum available: Xcode 16.2 (iOS 18.2 SDK)
- Required: Xcode 26.0 (iOS 19+ SDK)

**Workaround:** Local CD system on developer machine until GitHub Actions supports Xcode 26.

**Fixes Applied to Workflow:**
1. ✅ Added `SKIP_GIT_CHECK: "true"` - Bypasses git dirty check during CI
2. ✅ Removed deprecated `xcversion` - Uses `setup-xcode` action instead
3. ✅ Removed `latest_testflight_build_number` from `build_ipa` lane - Avoids needing Apple credentials during build phase (build number set by workflow using PlistBuddy)

### Android Deployment - Configured

**Status:** GitHub Actions workflow configured and ready.

**Requirements:**
1. ✅ Service account JSON key in `PLAY_STORE_JSON_KEY` secret
2. ⚠️ Service account must be invited in **Play Console** (Users and permissions)
   - Email: `play-store-publisher@just-spent-478016.iam.gserviceaccount.com`
   - Permissions: Releases (View and manage), App information (View)

**Common Errors Fixed:**
- "The caller does not have permission" → Add service account in Play Console (not just Cloud Console)
- Base64 with line breaks → Use `base64 | tr -d '\n' | pbcopy`

### Next Steps

1. **Android:** Verify Play Console permissions, then test deployment
2. **iOS:** Set up local CD system using Fastlane on developer Mac
3. **Future:** Migrate iOS back to GitHub Actions when Xcode 26 is supported

---

## 🏠 Local CD System (iOS)

Until GitHub Actions supports Xcode 26, use local Fastlane deployment.

### Setup

```bash
# Navigate to iOS directory
cd ios

# Install dependencies
bundle install

# Configure environment variables
export APPLE_ID="your-apple-id@email.com"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export APPLE_TEAM_ID="XXXXXXXXXX"

# Or add to ~/.zshrc or ~/.bash_profile
```

### Deployment Commands

```bash
# Build IPA for distribution
cd ios
bundle exec fastlane build_ipa

# Upload to TestFlight
bundle exec fastlane upload_testflight

# Complete beta workflow (test + build + upload)
bundle exec fastlane beta

# Full release workflow
bundle exec fastlane release
```

### Local CD Script (Recommended)

Create `scripts/deploy-ios-local.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Starting iOS Local Deployment..."

# Ensure we're in the right directory
cd "$(dirname "$0")/../ios"

# Run tests first
echo "🧪 Running tests..."
xcodebuild test -project JustSpent/JustSpent.xcodeproj -scheme JustSpent \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Build and upload
echo "📦 Building IPA..."
bundle exec fastlane build_ipa

echo "☁️ Uploading to TestFlight..."
bundle exec fastlane upload_testflight

echo "✅ iOS deployment complete!"
```

### Advantages of Local CD

- ✅ Uses your Xcode 26 installation
- ✅ Faster builds (no VM overhead)
- ✅ Direct access to signing certificates
- ✅ Immediate feedback

### When to Migrate Back to GitHub Actions

Monitor GitHub Actions runner updates:
- https://github.com/actions/runner-images/releases
- Look for Xcode 26 in `macos-latest` or `macos-15` images

---

**Last Updated:** 2025-11-18
**Maintained By:** Development Team
**Version:** 1.1.0
