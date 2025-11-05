# Just Spent - CI/CD Setup Guide

## Overview

This document describes the CI/CD pipeline setup for the Just Spent project, covering both iOS and Android platforms.

## Architecture

### Workflow Structure

```
Pull Request / Push to main/develop
    ↓
pr-checks.yml (Orchestrator)
    ├── ci-android.yml (Android Pipeline)
    └── ci-ios.yml (iOS Pipeline)
```

### Phase 1: Basic CI/CD (Current)

**Status:** ✅ Implemented

This phase includes:
- Automated builds on PR and push
- Unit test execution
- UI test execution
- Code coverage reporting via Codecov
- Test result artifacts

## Workflows

### 1. PR Checks (`pr-checks.yml`)

**Triggers:**
- Pull requests to `main` or `develop`
- Pushes to `main` or `develop`

**Features:**
- Runs both platform checks in parallel
- Cancels in-progress runs for the same PR
- Summary job that depends on both platforms

### 2. Android CI (`ci-android.yml`)

**Jobs:**

**Build and Test:**
- Runs on: `ubuntu-latest`
- Timeout: 30 minutes
- JDK: 17 (Temurin distribution)
- Cache: Gradle dependencies

**Steps:**
1. Build Debug APK
2. Run unit tests
3. Generate Jacoco coverage report
4. Upload test results
5. Upload coverage to Codecov

**UI Tests:**
- Runs on: `macos-latest` (required for emulator)
- Timeout: 45 minutes
- Emulator: API 34, Pixel 6 profile

**Steps:**
1. Run instrumented tests on Android emulator
2. Upload UI test results
3. Upload screenshots on failure

### 3. iOS CI (`ci-ios.yml`)

**Jobs:**

**Build and Test:**
- Runs on: `macos-14` (Xcode 15+)
- Timeout: 30 minutes
- Xcode: 15.2
- Simulator: iPhone 16, iOS 17.2

**Steps:**
1. Build iOS app (Debug configuration)
2. Run unit tests (JustSpentTests)
3. Run UI tests (JustSpentUITests)
4. Convert xcresult to coverage format
5. Upload test results
6. Upload coverage to Codecov

## Local Development

### Android Testing

```bash
cd android

# Run unit tests (fast)
./test.sh unit

# Run UI tests (requires emulator)
./test.sh ui

# Run all tests
./test.sh all

# Run with coverage
./test.sh coverage

# Clean and test
./test.sh clean
```

### iOS Testing

```bash
cd ios

# Run unit tests
./test.sh unit

# Run UI tests
./test.sh ui

# Run all tests
./test.sh all

# Run with coverage
./test.sh coverage

# Build only
./test.sh build

# Clean and test
./test.sh clean
```

**Note:** Install `xcpretty` for prettier output:
```bash
gem install xcpretty
```

## Code Coverage

### Configuration

Coverage is configured in `.codecov.yml` with the following targets:

- **Project Coverage:** 80% target (±5% threshold)
- **Patch Coverage:** 70% target (±5% threshold)

### Viewing Coverage

**In Pull Requests:**
- Codecov bot comments on PRs with coverage changes
- GitHub Checks show coverage status

**Locally:**

**Android:**
```bash
cd android
./test.sh coverage
open app/build/reports/jacoco/test/html/index.html
```

**iOS:**
```bash
cd ios
./test.sh coverage
xcrun xccov view --report test-results.xcresult
```

## CI/CD Requirements

### GitHub Secrets

For Phase 1 (Basic CI/CD), only Codecov token is needed:

- `CODECOV_TOKEN` - Token for uploading coverage reports

### Setting up Codecov

1. Go to [codecov.io](https://codecov.io)
2. Sign in with GitHub
3. Add the Just Spent repository
4. Copy the token
5. Add to GitHub Secrets:
   - Repository Settings → Secrets and variables → Actions
   - New repository secret: `CODECOV_TOKEN`

## Troubleshooting

### Android Build Failures

**Issue:** Gradle build fails
```bash
# Solution: Clear Gradle caches locally
cd android
./gradlew clean
./gradlew --stop
rm -rf ~/.gradle/caches
```

**Issue:** UI tests fail to start emulator
```bash
# CI uses android-emulator-runner action automatically
# Locally, ensure emulator is running:
adb devices
```

### iOS Build Failures

**Issue:** Xcode build fails
```bash
# Solution: Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**Issue:** Simulator not found
```bash
# List available simulators
xcrun simctl list devices

# Boot iPhone 16 simulator
xcrun simctl boot "iPhone 16"
```

**Issue:** Code signing errors
```bash
# CI disables code signing automatically
# Locally, use test.sh which handles it
```

### Coverage Upload Failures

**Issue:** Codecov upload fails
- Check `CODECOV_TOKEN` is set in GitHub Secrets
- Verify coverage files are generated
- Check Codecov action version is up to date

## Performance Benchmarks

### Expected CI Times

| Platform | Build | Unit Tests | UI Tests | Total |
|----------|-------|------------|----------|-------|
| Android  | ~2 min | ~1 min | ~8 min | ~11 min |
| iOS      | ~3 min | ~2 min | ~5 min | ~10 min |
| **Both** | - | - | - | **~15 min** |

*Times may vary based on GitHub Actions runner availability*

## Future Phases

### Phase 2: Beta Deployment (Planned)

- Fastlane integration
- Automated beta deployment
- TestFlight (iOS) automation
- Google Play Internal Testing (Android)
- Build number auto-increment
- Changelog generation

### Phase 3: Production Pipeline (Planned)

- Semantic versioning
- Production deployment workflows
- Manual approval gates
- Release automation
- Build notifications
- Crash analytics integration

## Best Practices

### For Developers

1. **Run tests locally before pushing:**
   ```bash
   cd android && ./test.sh all
   cd ios && ./test.sh all
   ```

2. **Check coverage locally:**
   ```bash
   cd android && ./test.sh coverage
   cd ios && ./test.sh coverage
   ```

3. **Fix failing tests immediately** - Don't let them pile up

4. **Write tests for new features** - Maintain 80%+ coverage

### For CI/CD

1. **Don't skip CI checks** - They exist for a reason
2. **Fix failing builds immediately** - Broken builds block everyone
3. **Monitor coverage trends** - Don't let coverage decrease
4. **Review test failures** - They often indicate real issues

## Support

For CI/CD issues:
1. Check this documentation
2. Review GitHub Actions logs
3. Check test.sh script output
4. Review `.github/workflows/` files

## Changelog

### 2025-01-29 - Phase 1 Implementation

- ✅ Created GitHub Actions workflows
- ✅ Android CI/CD pipeline (build + test + coverage)
- ✅ iOS CI/CD pipeline (build + test + coverage)
- ✅ Codecov integration
- ✅ iOS test script (matching Android pattern)
- ✅ Parallel platform testing
- ✅ Test artifact uploads

---

**Maintained by:** Development Team
**Last Updated:** January 29, 2025
**Phase:** 1 (Basic CI/CD)
