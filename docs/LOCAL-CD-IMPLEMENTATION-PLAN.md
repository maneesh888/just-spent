# Local CD Implementation Plan - Comprehensive Reference Document

This document provides complete implementation details for creating a local continuous deployment (CD) system that mirrors the working GitHub Actions pipeline.

---

## 1. Project Overview

**Goal**: Create shell scripts that enable deployment to TestFlight (iOS) and Play Store (Android) directly from your Mac, replicating the exact workflow currently running in GitHub Actions.

**Benefits**:
- Faster deployment (3-8 min vs 5-12 min on GitHub)
- No GitHub Actions minutes consumed
- No network dependency for build/test phases
- Full control over deployment timing
- Useful as backup if GitHub Actions fails

---

## 2. Files to Create

### 2.1 Main Deployment Scripts

#### `scripts/deploy-ios.sh` (~200 lines)
Complete iOS deployment pipeline from build to TestFlight.

**Responsibilities**:
1. Load iOS secrets and environment variables
2. Validate prerequisites (Xcode, Ruby, git clean state)
3. Install dependencies (`bundle install`)
4. Setup iOS signing (certificate + provisioning profile)
5. Run unit tests
6. Increment build number (timestamp-based)
7. Build IPA via Fastlane
8. Setup App Store Connect API key
9. Upload to TestFlight
10. Cleanup signing assets
11. Send macOS notification

**Key Functions**:
```bash
validate_ios_prerequisites()  # Check Xcode, Ruby versions
setup_ios_signing()          # Import cert/profile to keychain
increment_ios_build()        # Update Info.plist build number
build_ios_ipa()              # Call Fastlane build_ipa lane
upload_to_testflight()       # Call Fastlane upload_testflight lane
cleanup_ios()                # Remove keychain, temp files
```

#### `scripts/deploy-android.sh` (~180 lines)
Complete Android deployment pipeline from build to Play Store.

**Responsibilities**:
1. Load Android secrets and environment variables
2. Validate prerequisites (Java 17, Gradle wrapper)
3. Install dependencies (`bundle install`)
4. Setup Android signing (keystore + properties file)
5. Run unit tests
6. Build signed AAB
7. Verify AAB creation
8. Setup Play Store service account
9. Deploy to selected track (internal/beta/production)
10. Cleanup signing assets
11. Send macOS notification

**Key Functions**:
```bash
validate_android_prerequisites()  # Check Java, Gradle
setup_android_signing()          # Decode keystore, create properties
build_android_aab()              # Call gradlew bundleRelease
deploy_to_play_store()           # Call Fastlane deploy_* lanes
cleanup_android()                # Remove keystore, JSON key
```

#### `scripts/deploy.sh` (~100 lines)
Unified deployment wrapper with simple interface.

**Usage Examples**:
```bash
./scripts/deploy.sh ios                          # iOS to TestFlight
./scripts/deploy.sh android                      # Android internal
./scripts/deploy.sh android beta                 # Android beta
./scripts/deploy.sh android production 0.1       # Android prod 10%
./scripts/deploy.sh all                          # Both platforms
```

**Responsibilities**:
- Parse command line arguments (platform, track, rollout)
- Source appropriate platform script
- Handle errors gracefully
- Generate deployment report
- Send summary notifications

---

### 2.2 Helper Scripts

#### `scripts/helpers/load-secrets.sh` (~80 lines)
Centralized secret management.

**Functions**:
```bash
load_secrets()              # Load from ~/.just-spent-secrets/.env
validate_ios_secrets()      # Check all iOS secrets present
validate_android_secrets()  # Check all Android secrets present
get_secret()                # Safe secret getter with validation
```

**Environment Variables Loaded**:
```bash
# iOS
APPLE_TEAM_ID
APP_STORE_CONNECT_API_KEY_KEY_ID
APP_STORE_CONNECT_API_KEY_ISSUER_ID
IOS_CERTIFICATES_PASSWORD
KEYCHAIN_PASSWORD

# Android
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD

# Paths
SECRETS_DIR="$HOME/.just-spent-secrets"
```

#### `scripts/helpers/ios-signing.sh` (~120 lines)
iOS code signing asset management.

**Functions**:
```bash
create_build_keychain()
  # Create temporary keychain for signing
  # Set as default keychain
  # Unlock with KEYCHAIN_PASSWORD
  # Set timeout to 3600 seconds

import_distribution_certificate()
  # Decode certificate.p12 if base64
  # Import to build keychain
  # Grant codesign permissions
  # Set key partition list

import_provisioning_profile()
  # Create ~/Library/MobileDevice/Provisioning Profiles/
  # Copy or decode profile
  # Extract UUID from profile
  # Rename to UUID.mobileprovision

cleanup_ios_signing()
  # Delete build.keychain
  # Restore original default keychain
  # Remove temporary certificate file
  # Keep provisioning profile (reusable)
```

**Security Considerations**:
- Keychain auto-locks after 1 hour
- Certificate removed after deployment
- Temporary files deleted
- Profile kept for reuse (not sensitive)

#### `scripts/helpers/android-signing.sh` (~100 lines)
Android keystore and signing configuration.

**Functions**:
```bash
setup_android_keystore()
  # Copy keystore from secrets dir to android/app/
  # OR decode from base64 if needed
  # Verify keystore exists and is readable
  # Set correct permissions (600)

create_keystore_properties()
  # Create android/keystore.properties with:
  #   RELEASE_STORE_PASSWORD
  #   RELEASE_KEY_PASSWORD
  #   RELEASE_KEY_ALIAS
  #   RELEASE_STORE_FILE=keystore.jks
  # Ensure file is in .gitignore

decode_play_store_credentials()
  # Decode service account JSON
  # Save to android/play-store-key.json
  # Verify JSON is valid
  # Set SUPPLY_JSON_KEY env var

cleanup_android_signing()
  # Remove android/app/keystore.jks
  # Remove android/keystore.properties
  # Remove android/play-store-key.json
  # Clear SUPPLY_JSON_KEY env var
```

#### `scripts/helpers/notifications.sh` (~60 lines)
macOS notification system.

**Functions**:
```bash
notify_success()
  # Display success notification
  # Sound: "Glass"
  # Title: "Just Spent CD"
  # Body: Platform, track, build number

notify_failure()
  # Display failure notification
  # Sound: "Basso"
  # Title: "Just Spent CD Failed"
  # Body: Platform, error summary, log location

notify_deployment_started()
  # Display starting notification
  # Sound: "Submarine"
  # Body: Platform, estimated time
```

---

### 2.3 Configuration Files

#### `scripts/config/deploy.env.template`
Template showing all required variables (not the actual secrets).

```bash
# ==============================================
# Just Spent - Local Deployment Configuration
# ==============================================
#
# SETUP INSTRUCTIONS:
# 1. Copy this file to ~/.just-spent-secrets/.env
# 2. Fill in all values below
# 3. Ensure permissions: chmod 600 ~/.just-spent-secrets/.env
# 4. Never commit the actual .env file!

# ----------------------------------------------
# iOS Deployment Secrets
# ----------------------------------------------

# Apple Developer Account
APPLE_TEAM_ID="XXXXXXXXXX"  # 10-character team ID from Apple Developer

# App Store Connect API (from App Store Connect > Users and Access > Keys)
APP_STORE_CONNECT_API_KEY_KEY_ID="XXXXXXXXXX"  # Key ID (e.g., 56PCUNFT8S)
APP_STORE_CONNECT_API_KEY_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Issuer ID (UUID format)

# Signing Passwords
IOS_CERTIFICATES_PASSWORD="your-certificate-export-password"
KEYCHAIN_PASSWORD="temporary-keychain-password-for-ci"

# File Paths (relative to SECRETS_DIR)
IOS_CERTIFICATE_FILE="ios/certificate.p12"
IOS_PROVISIONING_PROFILE_FILE="ios/profile.mobileprovision"
IOS_API_KEY_FILE="ios/AuthKey_56PCUNFT8S.p8"

# ----------------------------------------------
# Android Deployment Secrets
# ----------------------------------------------

# Keystore Signing
ANDROID_KEYSTORE_PASSWORD="your-keystore-password"
ANDROID_KEY_ALIAS="justspent"
ANDROID_KEY_PASSWORD="your-key-password"

# File Paths (relative to SECRETS_DIR)
ANDROID_KEYSTORE_FILE="android/keystore.jks"
PLAY_STORE_JSON_KEY_FILE="android/play-store-key.json"

# ----------------------------------------------
# General Configuration
# ----------------------------------------------

# Secrets storage location
SECRETS_DIR="$HOME/.just-spent-secrets"

# Deployment options
SKIP_GIT_CHECK="true"  # Set to false to enforce clean git state
AUTO_INCREMENT_BUILD="true"  # Automatically increment build numbers
ENABLE_NOTIFICATIONS="true"  # macOS notifications on completion

# Logging
LOG_DIR="$HOME/.just-spent-deployment-logs"
LOG_LEVEL="info"  # debug, info, warn, error
```

---

## 3. Secret Files Storage

### 3.1 Directory Structure

```
~/.just-spent-secrets/
├── .env                              # Main config file with passwords
├── ios/
│   ├── certificate.p12               # Distribution certificate
│   ├── profile.mobileprovision       # App Store provisioning profile
│   └── AuthKey_56PCUNFT8S.p8        # App Store Connect API key
└── android/
    ├── keystore.jks                  # Release signing keystore
    └── play-store-key.json           # Service account credentials
```

### 3.2 How to Populate Secrets Directory

#### Initial Setup
```bash
# Create directory structure
mkdir -p ~/.just-spent-secrets/{ios,android}
chmod 700 ~/.just-spent-secrets

# Copy template
cp scripts/config/deploy.env.template ~/.just-spent-secrets/.env
chmod 600 ~/.just-spent-secrets/.env

# Edit with actual values
nano ~/.just-spent-secrets/.env
```

#### iOS Files

**1. Distribution Certificate (`certificate.p12`)**

Option A - Export from Keychain Access:
```bash
# 1. Open Keychain Access
# 2. Find "Apple Distribution: Your Name (TEAMID)" certificate
# 3. Right-click → Export
# 4. Save as certificate.p12 with password
# 5. Move to secrets directory
mv ~/Downloads/certificate.p12 ~/.just-spent-secrets/ios/
```

Option B - Use existing from GitHub secrets:
```bash
# If you have IOS_CERTIFICATES_P12 secret as base64
echo "$IOS_CERTIFICATES_P12" | base64 -d > ~/.just-spent-secrets/ios/certificate.p12
```

**2. Provisioning Profile (`profile.mobileprovision`)**

From Apple Developer Portal:
```bash
# 1. Go to developer.apple.com → Certificates, IDs & Profiles
# 2. Provisioning Profiles → App Store
# 3. Find "Just Spent Provisioning Profile"
# 4. Download
# 5. Move to secrets directory
mv ~/Downloads/Just_Spent_Provisioning_Profile.mobileprovision \
   ~/.just-spent-secrets/ios/profile.mobileprovision
```

**3. App Store Connect API Key (`AuthKey.p8`)**

Already have this file:
```bash
cp /Users/maneesh/Downloads/AuthKey_56PCUNFT8S.p8 \
   ~/.just-spent-secrets/ios/
```

#### Android Files

**1. Release Keystore (`keystore.jks`)**

Option A - Decode from GitHub secret:
```bash
# Get ANDROID_KEYSTORE_BASE64 from GitHub secrets
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > ~/.just-spent-secrets/android/keystore.jks
chmod 600 ~/.just-spent-secrets/android/keystore.jks
```

Option B - Use existing file:
```bash
# If you have the file locally
cp /path/to/your/keystore.jks ~/.just-spent-secrets/android/
```

**2. Play Store Service Account (`play-store-key.json`)**

Option A - Decode from GitHub secret:
```bash
# Get PLAY_STORE_JSON_KEY from GitHub secrets
echo "$PLAY_STORE_JSON_KEY" | base64 -d > ~/.just-spent-secrets/android/play-store-key.json
chmod 600 ~/.just-spent-secrets/android/play-store-key.json
```

Option B - Download from Google Cloud Console:
```bash
# 1. Go to console.cloud.google.com
# 2. IAM & Admin → Service Accounts
# 3. Find "play-store-publisher" service account
# 4. Keys → Add Key → Create New Key → JSON
# 5. Save and move
mv ~/Downloads/just-spent-*.json ~/.just-spent-secrets/android/play-store-key.json
```

---

## 4. Implementation Details

### 4.1 Build Number Strategy

**iOS Build Numbers**:
```bash
# GitHub Actions uses: github.run_number (sequential: 1, 2, 3...)
# Local uses: timestamp (YYMMDDHHmm format)

# Example in deploy-ios.sh:
increment_ios_build_number() {
    local BUILD_NUMBER=$(date +%y%m%d%H%M)
    local PLIST_PATH="ios/JustSpent/JustSpent/Info.plist"

    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$PLIST_PATH"

    echo "Build number set to: $BUILD_NUMBER"
}

# Result: Build 2511200830 (November 20, 2025, 8:30 AM)
```

**Android Build Numbers**:
```bash
# Handled by versionCode in build.gradle
# Increment manually using bump-version.sh before deploying
# No automatic increment in local script (to match GitHub Actions)
```

### 4.2 Fastlane Lanes

**iOS Lanes** (from `ios/fastlane/Fastfile`):

```ruby
# Lane 1: build_ipa
# - Builds IPA for App Store distribution
# - Export method: app-store
# - Output: ./build/JustSpent.ipa
# - Signing: Manual with provisioning profile
# Call from script:
bundle exec fastlane build_ipa

# Lane 2: upload_testflight
# - Uploads IPA to TestFlight
# - Uses App Store Connect API key
# - Generates changelog from git commits
# - Group: Internal Testers
# - No external distribution
# Call from script:
APP_STORE_CONNECT_API_KEY_KEY_ID="$KEY_ID" \
APP_STORE_CONNECT_API_KEY_ISSUER_ID="$ISSUER_ID" \
bundle exec fastlane upload_testflight
```

**Android Lanes** (from `android/fastlane/Fastfile`):

```ruby
# Lane 1: deploy_internal
# - Deploys to Internal Testing track
# - Upload only, no metadata
# Call from script:
SUPPLY_JSON_KEY="./play-store-key.json" \
bundle exec fastlane deploy_internal

# Lane 2: deploy_beta
# - Deploys to Beta (Closed Testing) track
# - Uploads metadata and release notes
# Call from script:
SUPPLY_JSON_KEY="./play-store-key.json" \
bundle exec fastlane deploy_beta

# Lane 3: deploy_production
# - Deploys to Production track
# - Supports rollout percentage
# - Uploads full metadata
# Call from script:
SUPPLY_JSON_KEY="./play-store-key.json" \
bundle exec fastlane deploy_production rollout_percentage:0.1
```

### 4.3 Error Handling

**Standard Error Handling Pattern**:
```bash
# Set strict error handling
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failures

# Function wrapper with error handling
run_with_error_handling() {
    local command="$1"
    local error_message="$2"
    local log_file="$3"

    if ! $command >> "$log_file" 2>&1; then
        echo "❌ $error_message"
        echo "📋 Log file: $log_file"
        notify_failure "$error_message" "$log_file"
        cleanup  # Always cleanup on error
        exit 1
    fi
}

# Example usage:
run_with_error_handling \
    "bundle exec fastlane build_ipa" \
    "iOS IPA build failed" \
    "$LOG_DIR/ios_build.log"
```

**Cleanup on Exit**:
```bash
# Trap to ensure cleanup always runs
trap cleanup EXIT
trap 'cleanup; exit 130' INT  # Ctrl+C
trap 'cleanup; exit 143' TERM  # Kill signal

cleanup() {
    echo "🧹 Cleaning up..."

    # iOS cleanup
    if [[ -n "${BUILD_KEYCHAIN:-}" ]]; then
        security delete-keychain "$BUILD_KEYCHAIN" 2>/dev/null || true
    fi

    # Android cleanup
    rm -f android/app/keystore.jks
    rm -f android/keystore.properties
    rm -f android/play-store-key.json

    # Restore original keychain (iOS)
    if [[ -n "${ORIGINAL_KEYCHAIN:-}" ]]; then
        security default-keychain -s "$ORIGINAL_KEYCHAIN"
    fi
}
```

### 4.4 Logging

**Log Directory Structure**:
```
~/.just-spent-deployment-logs/
├── 2025-11-20_083045_ios_deploy.log         # Full deployment log
├── 2025-11-20_083045_ios_build.log          # Build output
├── 2025-11-20_083045_ios_test.log           # Test output
├── 2025-11-20_083045_android_deploy.log     # Full deployment log
├── 2025-11-20_083045_android_build.log      # Build output
└── deployment-history.json                   # Deployment tracking
```

**Logging Implementation**:
```bash
# Initialize logging
LOG_TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
LOG_DIR="$HOME/.just-spent-deployment-logs"
mkdir -p "$LOG_DIR"

# Log functions
log_info() {
    echo "[INFO] $(date +%H:%M:%S) $*" | tee -a "$DEPLOYMENT_LOG"
}

log_error() {
    echo "[ERROR] $(date +%H:%M:%S) $*" | tee -a "$DEPLOYMENT_LOG" >&2
}

log_command() {
    local cmd="$1"
    local log_file="$2"

    log_info "Running: $cmd"
    eval "$cmd" >> "$log_file" 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_info "✅ Command succeeded"
    else
        log_error "❌ Command failed with exit code $exit_code"
        return $exit_code
    fi
}
```

### 4.5 Notifications

**macOS Notification Implementation**:
```bash
notify() {
    local title="$1"
    local message="$2"
    local sound="${3:-Glass}"

    if [[ "${ENABLE_NOTIFICATIONS:-true}" == "true" ]]; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
    fi
}

notify_success() {
    local platform="$1"
    local track="$2"
    local build_number="$3"
    local duration="$4"

    notify \
        "Just Spent CD - Success" \
        "$platform deployed to $track (build $build_number) in $duration" \
        "Glass"
}

notify_failure() {
    local platform="$1"
    local error_msg="$2"
    local log_file="$3"

    notify \
        "Just Spent CD - Failed" \
        "$platform deployment failed: $error_msg\nLog: $log_file" \
        "Basso"
}
```

---

## 5. Usage Examples

### 5.1 Deploy iOS to TestFlight
```bash
# Full deployment
./scripts/deploy.sh ios

# What happens:
# 1. Loads secrets from ~/.just-spent-secrets/.env
# 2. Validates Xcode, Ruby, git status
# 3. Installs Fastlane dependencies
# 4. Imports certificate and provisioning profile
# 5. Runs unit tests
# 6. Increments build number to 2511200830
# 7. Builds IPA → ios/build/JustSpent.ipa
# 8. Uploads to TestFlight with changelog
# 9. Cleanup
# 10. Notification: "iOS deployed to TestFlight (build 2511200830) in 6m 32s"
```

### 5.2 Deploy Android to Internal Testing
```bash
# Deploy to internal track (default)
./scripts/deploy.sh android

# Explicit track specification
./scripts/deploy.sh android internal

# What happens:
# 1. Loads secrets
# 2. Validates Java 17, Gradle
# 3. Installs Fastlane dependencies
# 4. Decodes keystore and creates keystore.properties
# 5. Runs unit tests
# 6. Builds signed AAB → android/app/build/outputs/bundle/release/app-release.aab
# 7. Decodes Play Store service account JSON
# 8. Uploads to Internal Testing track
# 9. Cleanup
# 10. Notification: "Android deployed to internal (build 4) in 4m 18s"
```

### 5.3 Deploy Android to Beta
```bash
./scripts/deploy.sh android beta

# Uses deploy_beta lane which:
# - Uploads to Closed Testing track
# - Includes metadata and release notes
# - Suitable for external beta testers
```

### 5.4 Deploy Android to Production with Rollout
```bash
# 10% rollout (default)
./scripts/deploy.sh android production 0.1

# 50% rollout
./scripts/deploy.sh android production 0.5

# Full 100% rollout
./scripts/deploy.sh android production 1.0

# Uses deploy_production lane with rollout percentage
```

### 5.5 Deploy Both Platforms
```bash
./scripts/deploy.sh all

# Sequential execution:
# 1. Deploy iOS to TestFlight
# 2. Deploy Android to Internal Testing
# 3. Combined notification with both results
```

---

## 6. Documentation Updates

### 6.1 Update `LOCAL-CI.md`

Add new section:

```markdown
## Local Continuous Deployment (CD)

### Quick Start

1. **Setup secrets directory**:
   ```bash
   mkdir -p ~/.just-spent-secrets/{ios,android}
   cp scripts/config/deploy.env.template ~/.just-spent-secrets/.env
   # Edit .env with your actual secrets
   ```

2. **Populate certificate/keystore files** (see DEPLOYMENT-README.md)

3. **Deploy**:
   ```bash
   ./scripts/deploy.sh ios              # iOS to TestFlight
   ./scripts/deploy.sh android beta     # Android to beta
   ```

### Available Commands

| Command | Description |
|---------|-------------|
| `./scripts/deploy.sh ios` | Deploy iOS to TestFlight |
| `./scripts/deploy.sh android` | Deploy Android to internal testing |
| `./scripts/deploy.sh android beta` | Deploy Android to beta track |
| `./scripts/deploy.sh android production 0.1` | Deploy Android to production (10% rollout) |
| `./scripts/deploy.sh all` | Deploy both platforms |

### Troubleshooting

**iOS certificate errors**:
```bash
# Verify certificate in keychain
security find-identity -v -p codesigning

# Re-import certificate
./scripts/helpers/ios-signing.sh import_distribution_certificate
```

**Android signing errors**:
```bash
# Verify keystore
keytool -list -v -keystore ~/.just-spent-secrets/android/keystore.jks

# Verify Play Store credentials
cat ~/.just-spent-secrets/android/play-store-key.json | jq .
```

**Build number conflicts**:
- Local uses timestamps, GitHub uses run_number
- No conflicts possible (different formats)
```

### 6.2 Update `CLAUDE.md`

Add to Quick Reference section:

```markdown
## 🚀 Deployment

### Local Deployment (CD)
```bash
# iOS to TestFlight
./scripts/deploy.sh ios

# Android to Play Store
./scripts/deploy.sh android             # Internal testing
./scripts/deploy.sh android beta        # Beta track
./scripts/deploy.sh android production 0.1  # Production 10%

# Both platforms
./scripts/deploy.sh all
```

### GitHub Actions (Automatic)
- Pushes to `main` branch trigger CI/CD automatically
- Platform-specific tags: `v1.0.0-ios`, `v1.0.0-android`
- Manual workflow dispatch available

### Version Management
```bash
# Bump version before deployment
./scripts/bump-version.sh 1.2.0
git commit -am "chore: Release v1.2.0"
git tag v1.2.0
```
```

### 6.3 Update `.gitignore`

Add deployment-related entries:

```gitignore
# Deployment secrets (NEVER COMMIT THESE!)
scripts/config/deploy.env
*.p8
*.p12
*.mobileprovision
play-store-key.json
keystore.jks
keystore.properties

# Deployment logs
.deployment-logs/
*.deployment.log

# Temporary deployment files
AuthKey*.p8
certificate.p12
profile.mobileprovision
```

---

## 7. Prerequisites Checklist

Before implementing local CD:

### System Requirements
- [ ] macOS (required for iOS deployment)
- [ ] Xcode 15.0+ with command line tools
- [ ] Java 17 (`java -version`)
- [ ] Ruby 3.1+ (`ruby -version`)
- [ ] Bundler (`gem install bundler`)
- [ ] Android SDK (for Android deployment)

### Secret Files
- [ ] iOS distribution certificate (.p12)
- [ ] iOS App Store provisioning profile (.mobileprovision)
- [ ] iOS App Store Connect API key (.p8)
- [ ] Android release keystore (.jks)
- [ ] Play Store service account JSON
- [ ] All passwords documented in .env file

### Verification
```bash
# Verify Xcode
xcodebuild -version

# Verify Java
java -version  # Should show 17.x

# Verify Ruby and Bundler
ruby -version  # Should show 3.1+
bundle -version

# Verify Android SDK
echo $ANDROID_HOME  # Should point to SDK location

# Verify secrets directory
ls -la ~/.just-spent-secrets/
```

---

## 8. Testing the Implementation

### 8.1 Test iOS Deployment

```bash
# Dry run (script validation only, no actual deployment)
DRY_RUN=true ./scripts/deploy-ios.sh

# Test build only (no upload)
SKIP_UPLOAD=true ./scripts/deploy-ios.sh

# Full deployment test
./scripts/deploy.sh ios

# Verify in App Store Connect:
# https://appstoreconnect.apple.com/
# → Apps → Just Spent → TestFlight → Builds
```

### 8.2 Test Android Deployment

```bash
# Dry run
DRY_RUN=true ./scripts/deploy-android.sh

# Test build only
SKIP_UPLOAD=true ./scripts/deploy-android.sh

# Full deployment test
./scripts/deploy.sh android

# Verify in Play Console:
# https://play.google.com/console/
# → Just Spent → Internal testing → Releases
```

---

## 9. Comparison Matrix

### Local CD vs GitHub Actions

| Feature | GitHub Actions | Local CD | Notes |
|---------|----------------|----------|-------|
| **Speed** | 5-12 minutes | 3-8 minutes | Local avoids VM startup, network overhead |
| **Cost** | GitHub minutes | Free | Save ~10 min/deployment × $0.008/min = $0.08 |
| **Network** | Always required | Only for upload | Can build/test offline |
| **Build #** | `github.run_number` (1, 2, 3...) | Timestamp (2511200830) | Different but both valid |
| **Secrets** | GitHub Secrets | Local .env file | Both equally secure if managed properly |
| **Platform** | Ubuntu (Android), macOS (iOS) | Your Mac | Consistent environment locally |
| **Artifacts** | GitHub storage (30 days) | Local `build/` directory | Keep what you need |
| **Logs** | GitHub UI | `~/.just-spent-deployment-logs/` | Better local access |
| **Notifications** | Email/Slack via workflow | macOS native notifications | Immediate feedback |
| **Parallel** | Can run both platforms simultaneously | Sequential (one Mac) | GitHub advantage for speed |
| **Setup Time** | Already configured | 1-2 hours initial setup | One-time cost |
| **Debugging** | Check logs in GitHub UI | Direct file access | Easier debugging locally |

### When to Use Each

**Use GitHub Actions when**:
- ✅ Deploying from non-Mac computer
- ✅ Need automatic deployment on git push
- ✅ Want deployment history in GitHub
- ✅ Working in team (visibility for all)
- ✅ Want parallel iOS + Android deployment

**Use Local CD when**:
- ✅ Deploying from your Mac
- ✅ Need faster iteration (no queue time)
- ✅ Want to save GitHub Actions minutes
- ✅ Testing deployment configuration changes
- ✅ GitHub Actions is down (backup)
- ✅ Need offline capability (build/test phase)

---

## 10. Future Enhancements

### Phase 2 Features
1. **Version Management Integration**
   - Auto-call `bump-version.sh` before deployment
   - Validate version matches git tag
   - Block deployment if version not bumped

2. **Changelog Generation**
   - Generate from git commits since last tag
   - Format for TestFlight/Play Store
   - Include PR links and contributor names

3. **Multi-Environment Support**
   ```bash
   ./scripts/deploy.sh ios --env staging
   ./scripts/deploy.sh android --env production
   ```

4. **Slack/Discord Integration**
   - Notify team on deployment success/failure
   - Include build number, version, changelog
   - Link to App Store Connect/Play Console

5. **Deployment History Tracking**
   - JSON database of all deployments
   - Query past deployments
   - Analytics (success rate, average time, etc.)

6. **Rollback Support**
   ```bash
   ./scripts/rollback.sh ios --to-build 39
   ./scripts/rollback.sh android --to-version 1.2.0
   ```

7. **Pre-Deployment Checks**
   - Run full test suite (not just unit tests)
   - Check for breaking API changes
   - Validate app store metadata
   - Verify certificates not expired

8. **Post-Deployment Validation**
   - Verify build appears in TestFlight/Play Console
   - Check build processing status
   - Download and verify IPA/AAB signature
   - Automated smoke tests on uploaded build

---

## 11. Security Considerations

### Secret Management
- ✅ Secrets stored outside repository (`~/.just-spent-secrets/`)
- ✅ File permissions: 600 (.env), 700 (directory)
- ✅ Never log secrets (sanitize all log output)
- ✅ Cleanup sensitive files after deployment
- ✅ Rotate secrets every 90 days

### Code Signing
- ✅ Temporary keychain auto-locks after 1 hour
- ✅ Certificate removed after deployment
- ✅ Keystore only accessible during build
- ✅ Provisioning profile UUID-named (not guessable)

### Best Practices
- ✅ Use App Store Connect API key (not password)
- ✅ Service account for Play Store (not personal account)
- ✅ Minimum permissions (upload only, not full admin)
- ✅ Audit log all deployments
- ✅ 2FA on Apple ID and Google account

---

## 12. Success Criteria

### Implementation Complete When:
- [ ] All scripts created and executable
- [ ] Secrets directory setup with all files
- [ ] iOS deployment to TestFlight successful
- [ ] Android deployment to Play Store successful
- [ ] Both platform deployment (all) working
- [ ] Error handling tested (fail gracefully)
- [ ] Notifications working
- [ ] Logs generated correctly
- [ ] Documentation updated (LOCAL-CI.md, CLAUDE.md)
- [ ] .gitignore updated to exclude secrets

### Performance Targets:
- [ ] iOS deployment: <8 minutes
- [ ] Android deployment: <6 minutes
- [ ] Both platforms: <15 minutes
- [ ] Error recovery: <30 seconds
- [ ] Notification delay: <5 seconds

### Quality Gates:
- [ ] 100% secret coverage (all GitHub secrets replicated)
- [ ] Zero secrets in git history
- [ ] All temporary files cleaned up
- [ ] Logs parseable and searchable
- [ ] Deployment history tracked

---

This comprehensive plan provides everything needed to implement a fully functional local CD system that perfectly mirrors the working GitHub Actions pipeline.
