# Just Spent - Continuous Deployment Guide

## Overview

This guide explains the **automated continuous deployment (CD)** process for Just Spent, covering both iOS and Android platforms. Our CD pipeline follows industry best practices for mobile app deployment.

## Table of Contents

1. [CD Concepts and Benefits](#cd-concepts-and-benefits)
2. [Deployment Architecture](#deployment-architecture)
3. [Standard Mobile App Deployment Process](#standard-mobile-app-deployment-process)
4. [iOS Deployment Pipeline](#ios-deployment-pipeline)
5. [Android Deployment Pipeline](#android-deployment-pipeline)
6. [Version Management](#version-management)
7. [Environment Configuration](#environment-configuration)
8. [Secrets Management](#secrets-management)
9. [Deployment Workflows](#deployment-workflows)
10. [Troubleshooting](#troubleshooting)

---

## CD Concepts and Benefits

### What is Continuous Deployment?

**Continuous Deployment (CD)** is the practice of automatically deploying every code change that passes all tests to production (or beta/staging environments). For mobile apps, this means:

- **Automated builds** triggered by git events
- **Automated testing** before deployment
- **Automated submission** to app stores
- **Phased rollouts** with beta testing
- **Zero-touch deployment** (no manual steps)

### Benefits

✅ **Speed**: Deploy in minutes, not hours/days
✅ **Reliability**: Eliminate human error in deployment
✅ **Consistency**: Same process every time
✅ **Traceability**: Full audit trail of all deployments
✅ **Confidence**: Automated tests prevent bad releases
✅ **Rollback**: Quick revert to previous versions

---

## Deployment Architecture

### Mobile App Deployment Flow

```
Developer → Git Push → CI/CD Pipeline → App Store Distribution
    ↓
Feature Branch
    ↓
Pull Request (CI runs tests)
    ↓
Merge to Main (Tests + Build)
    ↓
Tag Release (v1.0.0)
    ↓
┌─────────────────────────────────────────────────────────┐
│                    CD Pipeline                          │
│                                                         │
│  Build → Sign → Test → Upload → Submit for Review      │
└─────────────────────────────────────────────────────────┘
    ↓
┌─────────────────┬─────────────────┐
│      iOS        │     Android     │
├─────────────────┼─────────────────┤
│  TestFlight     │  Internal Test  │
│      ↓          │       ↓         │
│  Beta Testing   │  Open Beta      │
│      ↓          │       ↓         │
│  App Store      │  Production     │
└─────────────────┴─────────────────┘
```

### Deployment Tracks

**iOS (via App Store Connect):**
1. **TestFlight Internal** - Team members only
2. **TestFlight External** - Beta testers (up to 10,000)
3. **App Store** - Public production release

**Android (via Google Play Console):**
1. **Internal Testing** - Up to 100 testers, instant deployment
2. **Closed Testing (Alpha)** - Limited testers, feedback collection
3. **Open Testing (Beta)** - Public beta, gradual rollout
4. **Production** - All users, phased rollout (1% → 10% → 50% → 100%)

---

## Standard Mobile App Deployment Process

### Phase 1: Pre-Deployment (Development)

```bash
# 1. Develop feature on feature branch
git checkout -b feature/awesome-feature

# 2. Write tests (TDD mandatory)
# ... write tests, implement code ...

# 3. Run local CI to validate
./local-ci.sh --all

# 4. Commit and push
git commit -m "feat: Add awesome feature"
git push origin feature/awesome-feature

# 5. Create pull request
# GitHub Actions runs CI automatically
```

### Phase 2: Integration (Main Branch)

```bash
# 1. PR approved and merged to main
git checkout main
git pull

# 2. CI runs automatically on main
# - All tests (unit + UI)
# - Build validation
# - Code coverage check
# - Security scan

# 3. If all checks pass, code is ready for release
```

### Phase 3: Release Preparation

```bash
# 1. Bump version number
./scripts/bump-version.sh 1.2.3

# 2. Update changelog
# ... document changes ...

# 3. Commit version bump
git commit -am "chore: Bump version to 1.2.3"
git push

# 4. Create git tag
git tag -a v1.2.3 -m "Release v1.2.3"
git push --tags
```

### Phase 4: Automated Deployment

```
Git Tag Push (v1.2.3)
    ↓
GitHub Actions Workflow Triggered
    ↓
┌─────────────────────────────────────────┐
│        iOS Deployment Workflow          │
├─────────────────────────────────────────┤
│ 1. Checkout code                        │
│ 2. Setup Xcode environment              │
│ 3. Install dependencies                 │
│ 4. Run tests                            │
│ 5. Build IPA                            │
│ 6. Sign with distribution certificate   │
│ 7. Upload to TestFlight                 │
│ 8. Submit for external testing          │
│ 9. (Optional) Submit to App Store       │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│      Android Deployment Workflow        │
├─────────────────────────────────────────┤
│ 1. Checkout code                        │
│ 2. Setup Java/Android SDK               │
│ 3. Install dependencies                 │
│ 4. Run tests                            │
│ 5. Build AAB (Android App Bundle)       │
│ 6. Sign with upload keystore            │
│ 7. Upload to Play Console               │
│ 8. Promote to internal → beta → prod    │
│ 9. Phased rollout (1% → 100%)          │
└─────────────────────────────────────────┘
```

### Phase 5: Post-Deployment

- **Monitor crash reports** (Firebase Crashlytics)
- **Track user feedback** (App Store/Play Console reviews)
- **Monitor metrics** (DAU, retention, performance)
- **Rollback if needed** (revert tag, deploy previous version)

---

## iOS Deployment Pipeline

### Prerequisites

1. **Apple Developer Account** ($99/year)
2. **App Store Connect access**
3. **Distribution Certificate** (.p12 file)
4. **Provisioning Profile** (App Store distribution)
5. **App-specific password** (for automation)

### iOS Deployment Workflow Steps

#### 1. Setup Fastlane (Automation Tool)

Fastlane is the industry-standard tool for iOS/Android deployment automation.

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(
      project: "JustSpent.xcodeproj",
      scheme: "JustSpent",
      devices: ["iPhone 16"],
      clean: true
    )
  end

  desc "Build and upload to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: "JustSpent.xcodeproj")

    # Build the app
    build_app(
      scheme: "JustSpent",
      export_method: "app-store",
      output_directory: "./build",
      output_name: "JustSpent.ipa"
    )

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      notify_external_testers: false
    )
  end

  desc "Deploy to App Store"
  lane :release do
    # Build and upload
    beta

    # Submit for review
    upload_to_app_store(
      submit_for_review: true,
      automatic_release: false,
      force: true,
      skip_metadata: false,
      skip_screenshots: false
    )
  end
end
```

#### 2. GitHub Actions Workflow

```yaml
# .github/workflows/deploy-ios.yml
name: Deploy iOS

on:
  push:
    tags:
      - 'v*'  # Triggers on version tags (v1.0.0, v1.0.1, etc.)

jobs:
  deploy-ios:
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'

      - name: Install Fastlane
        run: |
          cd ios
          bundle install

      - name: Setup certificates and profiles
        env:
          CERTIFICATES_P12: ${{ secrets.IOS_CERTIFICATES_P12 }}
          CERTIFICATES_PASSWORD: ${{ secrets.IOS_CERTIFICATES_PASSWORD }}
          PROVISIONING_PROFILE: ${{ secrets.IOS_PROVISIONING_PROFILE }}
        run: |
          # Import certificates and provisioning profiles
          cd ios
          bundle exec fastlane match appstore --readonly

      - name: Run tests
        run: |
          cd ios
          bundle exec fastlane test

      - name: Build and upload to TestFlight
        env:
          FASTLANE_USER: ${{ secrets.APPLE_ID }}
          FASTLANE_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
          FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
        run: |
          cd ios
          bundle exec fastlane beta

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: ios/build/*.ipa
```

### iOS Deployment Process Explained

**Step 1: Developer pushes tag**
```bash
git tag v1.0.0
git push --tags
```

**Step 2: GitHub Actions triggered**
- Workflow detects tag push
- Checks out code at that tag

**Step 3: Environment setup**
- Installs Xcode 15
- Installs Fastlane and dependencies
- Imports signing certificates

**Step 4: Build process**
- Runs all tests (unit + UI)
- Increments build number automatically
- Builds IPA file with App Store configuration
- Signs with distribution certificate

**Step 5: Upload to TestFlight**
- Uploads IPA to App Store Connect
- Makes available to internal testers
- (Optional) Notifies external testers

**Step 6: App Store submission** (optional, manual trigger)
- Submits to App Review
- Sets release date and territories
- Configures phased release

**Step 7: Review and release**
- Apple reviews app (24-48 hours)
- Upon approval, app is released automatically or manually

---

## Android Deployment Pipeline

### Prerequisites

1. **Google Play Developer Account** ($25 one-time)
2. **Play Console access**
3. **Upload keystore** (.jks file)
4. **Service account JSON** (for API access)
5. **App created in Play Console**

### Android Deployment Workflow Steps

#### 1. Setup Fastlane (Android)

```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Run tests"
  lane :test do
    gradle(
      task: "test",
      project_dir: "android/"
    )
  end

  desc "Build release AAB"
  lane :build do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "android/",
      properties: {
        "android.injected.signing.store.file" => ENV["KEYSTORE_FILE"],
        "android.injected.signing.store.password" => ENV["KEYSTORE_PASSWORD"],
        "android.injected.signing.key.alias" => ENV["KEY_ALIAS"],
        "android.injected.signing.key.password" => ENV["KEY_PASSWORD"]
      }
    )
  end

  desc "Deploy to internal testing"
  lane :internal do
    build
    upload_to_play_store(
      track: 'internal',
      aab: 'app/build/outputs/bundle/release/app-release.aab',
      json_key: ENV["PLAY_STORE_JSON_KEY"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Promote internal to beta"
  lane :beta do
    upload_to_play_store(
      track: 'internal',
      track_promote_to: 'beta',
      json_key: ENV["PLAY_STORE_JSON_KEY"],
      skip_upload_aab: true,
      skip_upload_metadata: true
    )
  end

  desc "Deploy to production"
  lane :production do
    upload_to_play_store(
      track: 'beta',
      track_promote_to: 'production',
      json_key: ENV["PLAY_STORE_JSON_KEY"],
      rollout: '0.1',  # Start with 10% rollout
      skip_upload_aab: true,
      skip_upload_metadata: false
    )
  end

  desc "Increase production rollout"
  lane :increase_rollout do |options|
    percentage = options[:percentage] || 0.5
    upload_to_play_store(
      track: 'production',
      rollout: percentage.to_s,
      json_key: ENV["PLAY_STORE_JSON_KEY"],
      skip_upload_aab: true,
      skip_upload_metadata: true
    )
  end
end
```

#### 2. GitHub Actions Workflow

```yaml
# .github/workflows/deploy-android.yml
name: Deploy Android

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      track:
        description: 'Deployment track'
        required: true
        type: choice
        options:
          - internal
          - beta
          - production

jobs:
  deploy-android:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v2

      - name: Install Fastlane
        run: |
          cd android
          bundle install

      - name: Run tests
        run: |
          cd android
          ./gradlew testDebugUnitTest

      - name: Decode keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 -d > android/keystore.jks

      - name: Build and deploy
        env:
          KEYSTORE_FILE: ${{ github.workspace }}/android/keystore.jks
          KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
          PLAY_STORE_JSON_KEY: ${{ secrets.PLAY_STORE_JSON_KEY }}
        run: |
          cd android
          bundle exec fastlane internal

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: android-build
          path: android/app/build/outputs/bundle/release/*.aab

      - name: Cleanup keystore
        if: always()
        run: rm -f android/keystore.jks
```

### Android Deployment Process Explained

**Step 1: Developer pushes tag**
```bash
git tag v1.0.0
git push --tags
```

**Step 2: GitHub Actions triggered**
- Workflow detects tag push
- Checks out code at that tag

**Step 3: Environment setup**
- Installs Java 17 and Android SDK
- Installs Fastlane and dependencies
- Decodes and imports signing keystore

**Step 4: Build process**
- Runs all tests (unit + instrumentation if configured)
- Builds AAB (Android App Bundle)
- Signs with upload keystore

**Step 5: Upload to Play Console**
- Uploads AAB to internal testing track
- Uses Play Console API via service account

**Step 6: Progressive promotion**
```bash
# Manual promotion via GitHub Actions UI
# Or automatic promotion after testing period

# Internal (instant) → Beta (review complete) → Production (10% → 100%)
```

**Step 7: Phased rollout**
- Start: 10% of users
- Monitor crash-free rate, ratings
- Increase: 50% after 24 hours (if stable)
- Complete: 100% after 48 hours (if stable)

---

## Version Management

### Semantic Versioning

Follow **SemVer** (Semantic Versioning): `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (1.0.0 → 2.0.0)
- **MINOR**: New features, backward compatible (1.0.0 → 1.1.0)
- **PATCH**: Bug fixes, backward compatible (1.0.0 → 1.0.1)

### Version Bump Script

```bash
#!/bin/bash
# scripts/bump-version.sh

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: ./bump-version.sh <version>"
  echo "Example: ./bump-version.sh 1.2.3"
  exit 1
fi

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be in format MAJOR.MINOR.PATCH (e.g., 1.2.3)"
  exit 1
fi

# iOS: Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" ios/JustSpent/Info.plist

# Android: Update build.gradle
sed -i '' "s/versionName \".*\"/versionName \"$VERSION\"/" android/app/build.gradle

# Update package.json (if exists)
if [ -f "package.json" ]; then
  npm version $VERSION --no-git-tag-version
fi

echo "✅ Version bumped to $VERSION"
echo "📝 Next steps:"
echo "   1. Review changes: git diff"
echo "   2. Commit: git commit -am 'chore: Bump version to $VERSION'"
echo "   3. Tag: git tag -a v$VERSION -m 'Release v$VERSION'"
echo "   4. Push: git push && git push --tags"
```

### Build Number Auto-Increment

**iOS**: Fastlane handles automatically
```ruby
increment_build_number(xcodeproj: "JustSpent.xcodeproj")
```

**Android**: Use versionCode based on timestamp or git commits
```gradle
def getVersionCode() {
    return Integer.parseInt(new Date().format('yyMMddHH'))
}

android {
    defaultConfig {
        versionCode getVersionCode()
        versionName "1.0.0"
    }
}
```

---

## Environment Configuration

### Configuration Levels

1. **Development** - Local development
2. **Staging** - Pre-production testing
3. **Production** - Live app

### Environment Variables

**iOS** (`ios/JustSpent/Config/Config.xcconfig`):
```
API_BASE_URL = https://api.justspent.app
ENVIRONMENT = production
ANALYTICS_KEY = ${ANALYTICS_KEY_PROD}
```

**Android** (`android/app/build.gradle`):
```gradle
buildTypes {
    debug {
        buildConfigField "String", "API_BASE_URL", "\"https://dev.justspent.app\""
        buildConfigField "String", "ENVIRONMENT", "\"development\""
    }
    release {
        buildConfigField "String", "API_BASE_URL", "\"https://api.justspent.app\""
        buildConfigField "String", "ENVIRONMENT", "\"production\""
    }
}
```

---

## Secrets Management

### Required Secrets

**iOS:**
- `IOS_CERTIFICATES_P12` - Distribution certificate (base64 encoded)
- `IOS_CERTIFICATES_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE` - Provisioning profile (base64 encoded)
- `APPLE_ID` - Your Apple ID email
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- `MATCH_PASSWORD` - Fastlane Match repository encryption password

**Android:**
- `ANDROID_KEYSTORE_BASE64` - Upload keystore (base64 encoded)
- `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- `ANDROID_KEY_ALIAS` - Key alias
- `ANDROID_KEY_PASSWORD` - Key password
- `PLAY_STORE_JSON_KEY` - Service account JSON (base64 encoded)

### Adding Secrets to GitHub

```bash
# Navigate to: https://github.com/YOUR_USERNAME/just-spent/settings/secrets/actions

# Add each secret:
# 1. Click "New repository secret"
# 2. Name: IOS_CERTIFICATES_P12
# 3. Value: (paste base64 encoded certificate)
# 4. Click "Add secret"

# Encode files to base64:
base64 -i certificates.p12 -o certificates.p12.txt
base64 -i keystore.jks -o keystore.jks.txt
base64 -i service-account.json -o service-account.json.txt
```

### Secret Rotation

**Best Practices:**
- Rotate secrets every 90 days
- Use different keys for staging/production
- Never commit secrets to git
- Use secret scanning tools
- Audit secret access logs

---

## Deployment Workflows

### Workflow 1: Feature Development

```
1. Create feature branch: git checkout -b feature/new-feature
2. Develop with TDD: Write tests → Implement → Commit
3. Run local CI: ./local-ci.sh --all
4. Push: git push origin feature/new-feature
5. Create PR: GitHub Actions runs CI
6. Review and merge: Merge to main
```

### Workflow 2: Beta Release

```
1. Ensure main is stable: All CI checks pass
2. Bump version: ./scripts/bump-version.sh 1.1.0-beta.1
3. Commit: git commit -am "chore: Beta release 1.1.0-beta.1"
4. Tag: git tag v1.1.0-beta.1
5. Push: git push && git push --tags
6. Deploy: GitHub Actions deploys to TestFlight/Internal Testing
7. Test: QA team tests beta build
8. Collect feedback: Fix bugs, repeat if needed
```

### Workflow 3: Production Release

```
1. Finalize version: ./scripts/bump-version.sh 1.1.0
2. Update changelog: Document all changes
3. Commit: git commit -am "chore: Release 1.1.0"
4. Tag: git tag v1.1.0
5. Push: git push && git push --tags
6. Deploy: GitHub Actions deploys to production
7. Monitor: Watch crash reports, reviews, metrics
8. Rollout: Increase Android rollout percentage gradually
9. Complete: 100% rollout after stability confirmed
```

### Workflow 4: Hotfix

```
1. Create hotfix branch: git checkout -b hotfix/critical-bug main
2. Fix bug: Write test → Fix → Verify
3. Bump version: ./scripts/bump-version.sh 1.1.1
4. Commit: git commit -am "fix: Critical bug fix"
5. Tag: git tag v1.1.1
6. Push: git push && git push --tags
7. Deploy: GitHub Actions deploys immediately
8. Merge back: Merge hotfix to main and develop
```

---

## Troubleshooting

### iOS Issues

**Problem: "Code signing failed"**
- Check certificate expiration
- Verify provisioning profile matches bundle ID
- Ensure secrets are correctly configured

**Problem: "Upload to TestFlight failed"**
- Check Apple ID credentials
- Verify app-specific password
- Check App Store Connect API access

**Problem: "Build number already used"**
- Increment build number manually
- Check previous builds in App Store Connect

### Android Issues

**Problem: "Keystore not found"**
- Verify keystore is base64 encoded correctly
- Check secret name matches workflow

**Problem: "Service account access denied"**
- Verify service account has "Release Manager" role
- Check JSON key is valid and not expired

**Problem: "Version code must be greater"**
- Increment versionCode in build.gradle
- Use timestamp-based versionCode

### General Issues

**Problem: "Tests failing in CI but passing locally"**
- Check environment differences
- Verify all dependencies are installed
- Review CI logs for specific errors

**Problem: "Deployment workflow not triggering"**
- Verify tag format matches pattern (v*.*.*)
- Check workflow file syntax
- Review GitHub Actions logs

---

## Next Steps

1. **Read this guide completely**
2. **Set up Apple Developer and Google Play accounts**
3. **Generate signing certificates and keystores**
4. **Configure GitHub secrets**
5. **Test deployment workflows**
6. **Deploy first beta release**
7. **Monitor and iterate**

---

## Resources

### Official Documentation
- [Fastlane Docs](https://docs.fastlane.tools/)
- [App Store Connect API](https://developer.apple.com/app-store-connect/api/)
- [Google Play Console API](https://developers.google.com/android-publisher)
- [GitHub Actions](https://docs.github.com/en/actions)

### Tools
- [Fastlane Match](https://docs.fastlane.tools/actions/match/) - Certificate management
- [Fastlane Supply](https://docs.fastlane.tools/actions/supply/) - Play Store deployment
- [xcpretty](https://github.com/xcpretty/xcpretty) - Xcode output formatting

---

**Last Updated:** 2025-01-29
**Maintained By:** Development Team
**Related Docs:** `LOCAL-CI.md`, `CLAUDE.md`, `GIT-WORKFLOW-RULES.md`
