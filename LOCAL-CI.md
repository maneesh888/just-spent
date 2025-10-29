# Just Spent - Local CI/CD Documentation

## Overview

Just Spent uses a **hybrid CI/CD approach** that combines local development checks with cloud-based production safeguards:

- **Local CI**: Fast feedback during development (you run it)
- **GitHub Actions**: Automatic checks on main branch + manual trigger option

This approach gives you:
- ⚡ **3-5x faster** feedback (5-10 min vs 11-12 min on GitHub)
- 💰 **Zero cost** for feature branch development
- 🚀 **Instant results** with no network dependency
- 🛡️ **Safety net** for main branch with GitHub Actions

## Quick Start

### 1. First-Time Setup

```bash
# Install git hooks and setup local CI environment
./scripts/install-hooks.sh
```

This will:
- Make all scripts executable
- Install pre-commit hook
- Create results directory
- Validate your environment (Xcode, Java, etc.)
- Add `.ci-results/` to `.gitignore`

### 2. Run Your First Check

```bash
# Run full CI check (build + all tests)
./local-ci.sh --all

# Or run quick mode (build + unit tests only)
./local-ci.sh --all --quick
```

### 3. View Results

After running, you'll get:
- ✅ Colored terminal output with pass/fail status
- 🌐 HTML report that opens in your browser automatically
- 🔔 macOS notification when complete
- 📁 Detailed logs in `.ci-results/` directory

## Usage Guide

### Running Local CI

#### Basic Commands

```bash
# Run both iOS and Android (full suite)
./local-ci.sh --all

# Run iOS only
./local-ci.sh --ios

# Run Android only
./local-ci.sh --android

# Quick mode (build + unit tests, skip UI tests)
./local-ci.sh --all --quick

# Skip UI tests but run everything else
./local-ci.sh --all --skip-ui

# Get help
./local-ci.sh --help
```

#### What Gets Run

**Full Mode** (`--all`):
- iOS: Build → Unit Tests → UI Tests
- Android: Build → Unit Tests → UI Tests (if emulator running)
- Duration: ~5-10 minutes

**Quick Mode** (`--all --quick`):
- iOS: Build → Unit Tests only
- Android: Build → Unit Tests only
- Duration: ~2-3 minutes

### Pre-Commit Hook

The pre-commit hook runs automatically before every commit to prevent breaking changes.

#### Behavior

When you run `git commit`:
1. Hook runs `./local-ci.sh --all --quick` automatically
2. If tests pass → commit proceeds
3. If tests fail → commit is blocked

#### Bypassing the Hook

Sometimes you need to commit despite test failures (e.g., work-in-progress):

```bash
# Skip pre-commit hook (use sparingly!)
git commit --no-verify -m "WIP: Implementing feature"
```

**Best Practice**: Only bypass for WIP commits on feature branches, never on main.

#### Disabling the Hook

```bash
# Temporarily disable
rm .git/hooks/pre-commit

# Re-enable later
./scripts/install-hooks.sh
```

### Reading Test Results

#### Terminal Output

Colored output shows real-time progress:

```
🚀 Just Spent - Local CI Pipeline
================================

⏳ Building iOS app...
✅ iOS build completed (45s)

⏳ Running iOS unit tests...
✅ iOS unit tests passed (2m 15s)

⏳ Running iOS UI tests...
✅ iOS UI tests passed (1m 30s)

========================================
✅ All CI checks passed!
========================================
Total duration: 4m 30s
```

#### HTML Report

After each run, an HTML report is automatically generated and opened:

- **Status Card**: Overall pass/fail with duration
- **Platform Cards**: Breakdown for iOS and Android
- **Test Details**: Pass/fail status for each test suite
- **Log Files**: Links to detailed logs

Reports are saved in `.ci-results/report_*.html`

#### Detailed Logs

All logs are saved in `.ci-results/`:

```
.ci-results/
├── report_20250129_143022.html        # HTML report
├── report_20250129_143022.json        # JSON results
├── ios_build_20250129_143022.log      # iOS build log
├── ios_unit_20250129_143022.log       # iOS unit test log
├── ios_ui_20250129_143022.log         # iOS UI test log
├── ios_unit_20250129_143022.xcresult  # iOS test results
├── android_build_20250129_143022.log  # Android build log
├── android_unit_20250129_143022.log   # Android unit test log
└── android_ui_20250129_143022.log     # Android UI test log
```

To view a log:
```bash
# View most recent iOS build log
cat .ci-results/ios_build_*.log | tail -n 50

# View most recent Android unit test log
cat .ci-results/android_unit_*.log | tail -n 50

# Open test results in Xcode
open .ci-results/ios_unit_*.xcresult
```

### macOS Notifications

You'll receive desktop notifications:

- **Success**: Green "✅ All checks passed! (4m 30s)"
- **Failure**: Red "❌ CI checks failed! Check terminal for details."

## GitHub Actions Integration

### When GitHub Actions Run

GitHub Actions now only run automatically for:
- ✅ Pushes to `main` branch
- ✅ Pull requests to `main` branch

They **do not** run automatically for:
- ❌ Feature branches
- ❌ Pushes to `develop` or other branches
- ❌ Pull requests to non-main branches

### Manual Triggering

You can manually trigger GitHub Actions for any branch:

1. Go to: https://github.com/YOUR_USERNAME/just-spent/actions
2. Click "PR Checks" workflow
3. Click "Run workflow" button
4. Select your branch
5. Click "Run workflow"

This is useful for:
- Testing CI changes before merging
- Validating critical feature branches
- Running full suite in cloud environment

### When to Use What

| Scenario | Use Local CI | Use GitHub Actions |
|----------|--------------|-------------------|
| **During development** | ✅ Always | ❌ Not needed |
| **Before commit** | ✅ Automatic (hook) | ❌ Not needed |
| **Feature branch PR** | ✅ Run before creating | ⚠️ Manual trigger if desired |
| **Merging to main** | ✅ Good practice | ✅ Runs automatically |
| **After main merge** | ❌ Not needed | ✅ Runs automatically |
| **Testing CI config** | ✅ Quick validation | ✅ Full validation |

## Troubleshooting

### Local CI Issues

#### Tests Are Failing

1. **Check the logs**:
   ```bash
   cat .ci-results/*_build_*.log | tail -n 50
   ```

2. **Run tests manually** to get more details:
   ```bash
   # iOS
   cd ios/JustSpent
   xcodebuild test -project JustSpent.xcodeproj -scheme JustSpent \
     -destination 'platform=iOS Simulator,name=iPhone 16'

   # Android
   cd android
   ./gradlew testDebugUnitTest --info
   ```

3. **Check your environment**:
   ```bash
   xcodebuild -version  # Should show Xcode 15+
   java -version        # Should show Java 17
   ```

#### Script Won't Run

```bash
# Make sure scripts are executable
chmod +x local-ci.sh
chmod +x scripts/*.sh

# Or re-run setup
./scripts/install-hooks.sh
```

#### UI Tests Skipped (Android)

Android UI tests require a running emulator:

```bash
# Check if emulator is running
adb devices

# If no emulator, start one
emulator -avd Pixel_6_API_34 &

# Wait for emulator to boot, then run again
./local-ci.sh --android
```

#### Slow Performance

If local CI is slower than expected:

1. **Use quick mode** during development:
   ```bash
   ./local-ci.sh --all --quick
   ```

2. **Run single platform** when working on one:
   ```bash
   ./local-ci.sh --ios     # When working on iOS
   ./local-ci.sh --android # When working on Android
   ```

3. **Skip UI tests** until needed:
   ```bash
   ./local-ci.sh --all --skip-ui
   ```

### Pre-Commit Hook Issues

#### Hook Blocks All Commits

If the hook is too strict:

```bash
# Option 1: Bypass temporarily
git commit --no-verify -m "WIP: message"

# Option 2: Fix tests and commit properly
./local-ci.sh --all --quick
git commit -m "Fixed tests"

# Option 3: Disable hook
rm .git/hooks/pre-commit
```

#### Hook Doesn't Run

```bash
# Reinstall hook
./scripts/install-hooks.sh

# Verify it exists
ls -la .git/hooks/pre-commit
```

### GitHub Actions Issues

#### Workflows Not Running

Check your branch:
```bash
# Workflows only auto-run on main
git branch --show-current

# If on feature branch, either:
# 1. Merge to main (after local CI passes)
# 2. Manually trigger from GitHub UI
```

#### Want Auto-Run on Develop Too

Edit `.github/workflows/pr-checks.yml`:

```yaml
on:
  pull_request:
    branches:
      - main
      - develop  # Add this line
  push:
    branches:
      - main
      - develop  # Add this line
```

## Performance Comparison

### Local CI vs GitHub Actions

| Metric | Local CI | GitHub Actions |
|--------|----------|----------------|
| **Full Suite** | 5-10 min | 11-12 min |
| **Quick Mode** | 2-3 min | N/A |
| **Network Required** | No | Yes |
| **Cost** | Free | GitHub minutes |
| **Queue Time** | 0 sec | 30-60 sec |
| **Failure Rate** | ~5% | ~10% (improved with emulator optimizations) |

**Note**: GitHub Actions configuration optimized for reliability:
- **Ubuntu runners** (`ubuntu-latest`) - Best stability for Android emulator
- **KVM hardware acceleration** - Near-native performance for x86_64 emulation
- **API Level 28 (Android 9)** - Proven stable in CI environments (newer APIs have reliability issues)
- **Nexus 6 device profile** - Widely used and tested profile
- **Google APIs target** - Full Android feature set available for comprehensive testing
- **AVD caching** - Speeds up subsequent runs after initial boot
- **Explicit ADB commands** - `adb wait-for-device` ensures proper device detection
- **Runtime permissions** - Microphone permissions granted via ADB before tests run

**Architecture Choice**: Using `ubuntu-latest` with KVM + API 28:
- Linux runners provide superior emulator stability compared to macOS
- KVM hardware acceleration delivers near-native performance
- API 28 chosen over newer versions due to proven CI reliability
- Recommended by android-emulator-runner maintainers and community
- Trade-off: API 28 vs targetSdk 34, but prioritizes CI reliability

### Resource Usage

Local CI consumes:
- **Disk**: ~500MB for logs/results (cleaned periodically)
- **Memory**: ~4GB during iOS UI tests
- **CPU**: High during builds (2-3 minutes)

To clean up old results:
```bash
# Remove results older than 7 days
find .ci-results -name "*.log" -mtime +7 -delete
find .ci-results -name "*.html" -mtime +7 -delete
```

## Best Practices

### Development Workflow

```bash
# 1. Start feature branch
git checkout -b feature/my-feature

# 2. Make changes
# ... code, code, code ...

# 3. Run quick checks frequently
./local-ci.sh --all --quick

# 4. Before commit, run full suite
./local-ci.sh --all

# 5. Commit (pre-commit hook runs automatically)
git commit -m "feat: Implement awesome feature"

# 6. Push to GitHub
git push origin feature/my-feature

# 7. Create PR to main (GitHub Actions will run)
```

### When to Run What

**During Development**:
- Run `./local-ci.sh --ios` or `--android` for the platform you're working on
- Run frequently (every few changes)

**Before Committing**:
- Run `./local-ci.sh --all --quick` (or let pre-commit hook do it)
- Ensures no broken commits

**Before Creating PR**:
- Run `./local-ci.sh --all` (full suite)
- Ensures PR will pass GitHub Actions

**After Main Branch Changes**:
- Pull latest from main
- Run `./local-ci.sh --all` to ensure your branch still works

## Advanced Usage

### Integrating with IDE

#### Xcode

Add a run script build phase:
```bash
"$PROJECT_DIR/../local-ci.sh" --ios --quick
```

#### Android Studio

Add to `build.gradle`:
```groovy
task localCI(type: Exec) {
    commandLine '../local-ci.sh', '--android', '--quick'
}
```

### CI Statistics

View your CI history:
```bash
# List all reports
ls -lt .ci-results/report_*.html

# Count successes vs failures
grep -c '"overall_success": true' .ci-results/*.json
grep -c '"overall_success": false' .ci-results/*.json

# Average duration
grep '"duration":' .ci-results/*.json | \
  awk -F: '{sum+=$2} END {print sum/NR " seconds average"}'
```

### Custom Notifications

Edit `local-ci.sh` to customize notifications:

```bash
# Line ~340 for success
notify "Just Spent CI" "✅ All checks passed! ($(format_duration $TOTAL_DURATION))" "Glass"

# Line ~360 for failure
notify "Just Spent CI" "❌ CI checks failed! Check terminal for details." "Basso"
```

## Migration Guide

### Switching from GitHub-Only

If you were using only GitHub Actions before:

1. **Install local CI**:
   ```bash
   ./scripts/install-hooks.sh
   ```

2. **Test it works**:
   ```bash
   ./local-ci.sh --all
   ```

3. **Update workflow** (already done):
   - GitHub Actions now only run on main
   - You can still manually trigger for any branch

4. **Update habits**:
   - Run local CI before pushing (faster feedback)
   - Let GitHub Actions protect main branch
   - Save GitHub Actions minutes for production

### Going Back to GitHub-Only

If you want to revert:

1. **Remove pre-commit hook**:
   ```bash
   rm .git/hooks/pre-commit
   ```

2. **Update workflows** to run on all branches:
   Edit `.github/workflows/pr-checks.yml`:
   ```yaml
   on:
     pull_request:
       branches:
         - main
         - develop
         - '**'  # All branches
   ```

## FAQ

### Q: Do I have to use the pre-commit hook?

**A**: No, it's optional. You can remove it and run `./local-ci.sh` manually before commits.

### Q: Can I customize what the pre-commit hook runs?

**A**: Yes! Edit `.git/hooks/pre-commit` and change the command. For example, change `--quick` to `--skip-ui` or add `--ios` to run iOS only.

### Q: Why doesn't local CI upload to Codecov?

**A**: Local CI focuses on fast feedback. Codecov integration remains in GitHub Actions for the main branch, giving you official coverage badges without slowing down local development.

### Q: Can I run this in Docker?

**A**: iOS requires macOS (Xcode), so iOS tests must run on Mac. Android tests could run in Docker, but the setup complexity outweighs benefits for solo development.

### Q: How do I clean up old results?

**A**:
```bash
# Delete results older than 7 days
find .ci-results -mtime +7 -delete

# Or delete all results
rm -rf .ci-results
mkdir .ci-results
```

### Q: Can team members use this?

**A**: Yes! The hybrid approach works great for teams. Each developer gets fast local feedback, while GitHub Actions provides team visibility and PR checks.

## Support

### Getting Help

1. **Check this documentation** first
2. **View logs** in `.ci-results/`
3. **Run with verbose** output: check individual log files
4. **Compare with GitHub Actions** to see if issue is environmental

### Reporting Issues

When reporting issues, include:
- Command you ran
- Terminal output
- Contents of `.ci-results/*_build_*.log`
- Environment info: `xcodebuild -version` and `java -version`

---

**Happy coding with fast, reliable CI! 🚀**
