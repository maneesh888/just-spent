# Just Spent - Secrets and Credentials Setup Guide

## Overview

This guide walks you through setting up all required secrets and credentials for automated deployment of Just Spent to Apple App Store and Google Play Store.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [iOS Secrets Setup](#ios-secrets-setup)
3. [Android Secrets Setup](#android-secrets-setup)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Testing Your Setup](#testing-your-setup)
6. [Security Best Practices](#security-best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Accounts Required

- [ ] **Apple Developer Account** ($99/year)
- [ ] **Google Play Developer Account** ($25 one-time)
- [ ] **GitHub Account** (with admin access to repository)

### Tools Required

- [ ] **macOS** (for iOS certificate generation)
- [ ] **Xcode** 15.0+ (for iOS development)
- [ ] **Android Studio** (for Android keystore generation)
- [ ] **OpenSSL** (for certificate conversion)
- [ ] **base64** command (for encoding files)

---

## iOS Secrets Setup

### Step 1: Apple Developer Account Setup

1. **Create App ID in Apple Developer Portal**
   ```
   1. Go to: https://developer.apple.com/account/resources/identifiers/list
   2. Click "+" to create new App ID
   3. Select "App IDs" → "App"
   4. Fill in:
      - Description: Just Spent
      - Bundle ID: com.justspent.app (explicit)
   5. Select capabilities:
      - Siri
      - Push Notifications
      - In-App Purchase (if applicable)
   6. Click "Continue" → "Register"
   ```

2. **Create App in App Store Connect**
   ```
   1. Go to: https://appstoreconnect.apple.com/
   2. Click "My Apps" → "+" → "New App"
   3. Fill in:
      - Platform: iOS
      - Name: Just Spent
      - Primary Language: English
      - Bundle ID: com.justspent.app
      - SKU: justspent-ios (unique identifier)
   4. Click "Create"
   ```

### Step 2: Generate Distribution Certificate

**Option A: Using Xcode (Recommended)**

```bash
# 1. Open Xcode
# 2. Go to: Xcode → Settings → Accounts
# 3. Click "+" to add Apple ID
# 4. Select team
# 5. Click "Manage Certificates"
# 6. Click "+" → "Apple Distribution"
# 7. Certificate will be created and stored in Keychain

# Export certificate from Keychain
security find-identity -v -p codesigning

# Export to .p12 file
security export -k login.keychain -t identities \
  -f pkcs12 -o ios-distribution.p12 \
  -P YOUR_CERTIFICATE_PASSWORD
```

**Option B: Using Apple Developer Portal**

```
1. Go to: https://developer.apple.com/account/resources/certificates/list
2. Click "+" to create certificate
3. Select "Apple Distribution"
4. Follow instructions to create Certificate Signing Request (CSR)
5. Upload CSR
6. Download certificate (.cer file)
7. Import to Keychain
8. Export as .p12 file (see above)
```

### Step 3: Generate Provisioning Profile

```
1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Click "+" to create profile
3. Select "App Store Connect"
4. Select your App ID (com.justspent.app)
5. Select your Distribution Certificate
6. Name it: "Just Spent App Store Profile"
7. Click "Generate"
8. Download profile (.mobileprovision file)
```

### Step 4: Generate App-Specific Password

```
1. Go to: https://appleid.apple.com/account/manage
2. Sign in with your Apple ID
3. Go to "Security" section
4. Under "App-Specific Passwords", click "Generate"
5. Name it: "Just Spent Fastlane"
6. Copy the generated password (16 characters)
7. Save it securely
```

### Step 5: Encode iOS Files to Base64

```bash
# Navigate to where you saved the files
cd ~/Downloads

# Encode distribution certificate
base64 -i ios-distribution.p12 -o ios-distribution-base64.txt

# Encode provisioning profile
base64 -i JustSpent_AppStore.mobileprovision -o provisioning-profile-base64.txt

# View encoded content
cat ios-distribution-base64.txt
cat provisioning-profile-base64.txt
```

### iOS Secrets Summary

You should now have:

- [ ] `IOS_CERTIFICATES_P12` - Base64 encoded .p12 certificate
- [ ] `IOS_CERTIFICATES_PASSWORD` - Certificate password
- [ ] `IOS_PROVISIONING_PROFILE` - Base64 encoded .mobileprovision
- [ ] `APPLE_ID` - Your Apple ID email
- [ ] `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password
- [ ] `APPLE_TEAM_ID` - Team ID (10 characters, found in Developer Portal)

---

## Android Secrets Setup

### Step 1: Google Play Developer Account Setup

1. **Create Play Console Account**
   ```
   1. Go to: https://play.google.com/console/signup
   2. Pay $25 one-time registration fee
   3. Complete account setup
   ```

2. **Create App in Play Console**
   ```
   1. Go to: https://play.google.com/console/developers
   2. Click "Create app"
   3. Fill in:
      - App name: Just Spent
      - Default language: English (United States)
      - App or game: App
      - Free or paid: Free
   4. Accept declarations
   5. Click "Create app"
   ```

### Step 2: Generate Upload Keystore

```bash
# Generate keystore using keytool
keytool -genkey -v \
  -storetype PKCS12 \
  -keystore justspent-upload-keystore.jks \
  -alias justspent \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# You'll be prompted for:
# - Keystore password (save this!)
# - Key password (save this!)
# - Your name
# - Organization unit
# - Organization name
# - City/Locality
# - State/Province
# - Country code (2 letters)

# Verify keystore was created
ls -lh justspent-upload-keystore.jks

# View keystore info
keytool -list -v -keystore justspent-upload-keystore.jks
```

**Important:** Save these securely:
- Keystore file (`justspent-upload-keystore.jks`)
- Keystore password
- Key alias (`justspent`)
- Key password

### Step 3: Create Service Account

```
1. Go to Play Console: https://play.google.com/console/developers
2. Select "Just Spent" app
3. Go to: Setup → API access
4. Click "Create new service account"
5. Follow link to Google Cloud Console
6. In Cloud Console:
   - Click "Create Service Account"
   - Name: "just-spent-deployment"
   - Description: "Service account for automated deployments"
   - Click "Create and Continue"
7. Grant roles:
   - Role: "Service Account User"
   - Click "Continue" → "Done"
8. Back in service account list:
   - Click on the account you just created
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Select "JSON"
   - Click "Create"
   - JSON file will download
9. Back in Play Console:
   - Refresh the page
   - Grant access to the service account:
     - App permissions: "Just Spent"
     - Account permissions: "Release Manager"
   - Click "Invite user" → "Send invitation"
```

### Step 4: Encode Android Files to Base64

```bash
# Navigate to where you saved the files
cd ~/Downloads

# Encode keystore
base64 -i justspent-upload-keystore.jks -o keystore-base64.txt

# Encode service account JSON
base64 -i just-spent-deployment-*.json -o service-account-base64.txt

# View encoded content
cat keystore-base64.txt
cat service-account-base64.txt
```

### Android Secrets Summary

You should now have:

- [ ] `ANDROID_KEYSTORE_BASE64` - Base64 encoded .jks keystore
- [ ] `ANDROID_KEYSTORE_PASSWORD` - Keystore password
- [ ] `ANDROID_KEY_ALIAS` - Key alias (e.g., "justspent")
- [ ] `ANDROID_KEY_PASSWORD` - Key password
- [ ] `PLAY_STORE_JSON_KEY` - Base64 encoded service account JSON

---

## GitHub Secrets Configuration

### Step 1: Navigate to GitHub Secrets

```
1. Go to your repository: https://github.com/YOUR_USERNAME/just-spent
2. Click "Settings" tab
3. In left sidebar, click "Secrets and variables" → "Actions"
4. You'll see "Repository secrets" page
```

### Step 2: Add iOS Secrets

Click "New repository secret" for each:

**Secret 1: IOS_CERTIFICATES_P12**
```
Name: IOS_CERTIFICATES_P12
Value: [Paste content from ios-distribution-base64.txt]
```

**Secret 2: IOS_CERTIFICATES_PASSWORD**
```
Name: IOS_CERTIFICATES_PASSWORD
Value: [Your certificate password]
```

**Secret 3: IOS_PROVISIONING_PROFILE**
```
Name: IOS_PROVISIONING_PROFILE
Value: [Paste content from provisioning-profile-base64.txt]
```

**Secret 4: APPLE_ID**
```
Name: APPLE_ID
Value: [Your Apple ID email]
```

**Secret 5: APPLE_APP_SPECIFIC_PASSWORD**
```
Name: APPLE_APP_SPECIFIC_PASSWORD
Value: [Your 16-character app-specific password]
```

**Secret 6: APPLE_TEAM_ID**
```
Name: APPLE_TEAM_ID
Value: [Your 10-character team ID]
```

**Secret 7: KEYCHAIN_PASSWORD**
```
Name: KEYCHAIN_PASSWORD
Value: [Choose a strong password for CI keychain]
```

### Step 3: Add Android Secrets

Click "New repository secret" for each:

**Secret 1: ANDROID_KEYSTORE_BASE64**
```
Name: ANDROID_KEYSTORE_BASE64
Value: [Paste content from keystore-base64.txt]
```

**Secret 2: ANDROID_KEYSTORE_PASSWORD**
```
Name: ANDROID_KEYSTORE_PASSWORD
Value: [Your keystore password]
```

**Secret 3: ANDROID_KEY_ALIAS**
```
Name: ANDROID_KEY_ALIAS
Value: justspent
```

**Secret 4: ANDROID_KEY_PASSWORD**
```
Name: ANDROID_KEY_PASSWORD
Value: [Your key password]
```

**Secret 5: PLAY_STORE_JSON_KEY**
```
Name: PLAY_STORE_JSON_KEY
Value: [Paste content from service-account-base64.txt]
```

### Step 4: Verify All Secrets

After adding all secrets, you should see:

**iOS Secrets (7):**
- ✅ IOS_CERTIFICATES_P12
- ✅ IOS_CERTIFICATES_PASSWORD
- ✅ IOS_PROVISIONING_PROFILE
- ✅ APPLE_ID
- ✅ APPLE_APP_SPECIFIC_PASSWORD
- ✅ APPLE_TEAM_ID
- ✅ KEYCHAIN_PASSWORD

**Android Secrets (5):**
- ✅ ANDROID_KEYSTORE_BASE64
- ✅ ANDROID_KEYSTORE_PASSWORD
- ✅ ANDROID_KEY_ALIAS
- ✅ ANDROID_KEY_PASSWORD
- ✅ PLAY_STORE_JSON_KEY

---

## Testing Your Setup

### Test 1: Validate iOS Setup Locally

```bash
# Navigate to iOS directory
cd ios

# Install Fastlane
bundle install

# Test certificate import (will fail but shows if cert is valid)
fastlane test_unit
```

### Test 2: Validate Android Setup Locally

```bash
# Navigate to Android directory
cd android

# Install Fastlane
bundle install

# Validate Play Store credentials
export SUPPLY_JSON_KEY=/path/to/service-account.json
bundle exec fastlane validate_credentials
```

### Test 3: Test GitHub Actions (Dry Run)

```bash
# Create a test tag
git tag -a v0.0.1-test -m "Test deployment"
git push --tags

# Monitor workflow:
# Go to: https://github.com/YOUR_USERNAME/just-spent/actions

# If successful, delete test tag
git tag -d v0.0.1-test
git push --delete origin v0.0.1-test
```

---

## Security Best Practices

### 1. Secret Rotation

- [ ] Rotate iOS certificates before expiration (1 year)
- [ ] Rotate Android keystore passwords every 90 days
- [ ] Rotate app-specific passwords every 90 days
- [ ] Audit service account access monthly

### 2. Access Control

- [ ] Limit GitHub repository admin access
- [ ] Use separate service accounts per environment
- [ ] Enable 2FA on all accounts
- [ ] Review access logs regularly

### 3. Secret Storage

- [ ] Never commit secrets to git
- [ ] Use password manager for local secrets
- [ ] Encrypt local backups
- [ ] Keep keystore backups secure (offline)

### 4. Incident Response

If secrets are compromised:

**iOS:**
1. Revoke certificate in Apple Developer Portal
2. Generate new certificate
3. Update GitHub secrets
4. Regenerate provisioning profiles

**Android:**
1. Generate new keystore
2. Update app in Play Console (new signing key)
3. Update GitHub secrets
4. Issue app update ASAP

### 5. Backup Checklist

Keep secure backups of:

- [ ] iOS distribution certificate (.p12)
- [ ] iOS provisioning profile (.mobileprovision)
- [ ] Android keystore (.jks)
- [ ] All passwords in password manager
- [ ] Service account JSON file
- [ ] Team ID and App IDs

---

## Troubleshooting

### iOS Issues

**Problem: "No valid code signing identity found"**

Solution:
```bash
# Verify certificate is valid
security find-identity -v -p codesigning

# Check certificate expiration
security find-certificate -c "Apple Distribution" -p | openssl x509 -text | grep "Not After"

# Re-import certificate if needed
security import ios-distribution.p12 -k ~/Library/Keychains/login.keychain-db
```

**Problem: "Provisioning profile doesn't match bundle ID"**

Solution:
- Ensure bundle ID in Xcode matches provisioning profile
- Regenerate provisioning profile in Apple Developer Portal
- Re-encode and update GitHub secret

**Problem: "App-specific password invalid"**

Solution:
- Generate new app-specific password
- Update GitHub secret immediately
- Test with: `xcrun altool --list-apps -u YOUR_APPLE_ID -p APP_SPECIFIC_PASSWORD`

### Android Issues

**Problem: "Keystore not found"**

Solution:
```bash
# Verify base64 encoding
cat keystore.jks | base64 | base64 -d > test.jks
keytool -list -v -keystore test.jks  # Should work
```

**Problem: "Service account access denied"**

Solution:
- Verify service account has "Release Manager" role
- Check Play Console API access is enabled
- Ensure service account email is correct in JSON

**Problem: "Version code already exists"**

Solution:
- Increment versionCode in build.gradle
- Or use timestamp-based versionCode (auto-increments)

### GitHub Actions Issues

**Problem: "Secret not found"**

Solution:
- Verify secret name matches exactly (case-sensitive)
- Check secret is in correct repository
- Ensure workflow file references correct secret name

**Problem: "Base64 decode failed"**

Solution:
```bash
# Verify base64 encoding is clean (no newlines/spaces)
cat file.p12 | base64 | tr -d '\n' > file-base64.txt

# Test decode
cat file-base64.txt | base64 -d > test.p12
# Should produce valid file
```

---

## Verification Checklist

Before going to production, verify:

### iOS Checklist
- [ ] Distribution certificate is valid and not expired
- [ ] Provisioning profile matches bundle ID
- [ ] App exists in App Store Connect
- [ ] Apple ID has necessary permissions
- [ ] App-specific password is valid
- [ ] Team ID is correct
- [ ] All secrets are in GitHub

### Android Checklist
- [ ] Keystore is valid and backed up
- [ ] Service account JSON is valid
- [ ] Service account has "Release Manager" role
- [ ] App exists in Play Console
- [ ] Play Console API access is enabled
- [ ] All secrets are in GitHub

### GitHub Actions Checklist
- [ ] All 12 secrets are added
- [ ] Secret values are base64 encoded correctly
- [ ] Workflow files exist (deploy-ios.yml, deploy-android.yml)
- [ ] Test tag triggers workflows successfully
- [ ] Build artifacts are uploaded correctly

---

## Next Steps

Once secrets are configured:

1. **Test deployment workflow:**
   ```bash
   ./scripts/bump-version.sh 0.0.1-test
   git commit -am "chore: Test deployment"
   git tag v0.0.1-test
   git push --tags
   ```

2. **Monitor deployment:**
   - Watch GitHub Actions logs
   - Check App Store Connect for iOS build
   - Check Play Console for Android build

3. **Clean up test release:**
   - Remove test build from TestFlight
   - Remove test build from Play Console
   - Delete git tag: `git tag -d v0.0.1-test && git push --delete origin v0.0.1-test`

4. **Proceed with first real release:**
   ```bash
   ./scripts/bump-version.sh 1.0.0
   git commit -am "chore: Release v1.0.0"
   git tag v1.0.0
   git push && git push --tags
   ```

---

**Last Updated:** 2025-01-29
**Maintained By:** Development Team
**Related Docs:** `DEPLOYMENT-GUIDE.md`, `CLAUDE.md`
