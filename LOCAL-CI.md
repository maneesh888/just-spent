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

# Stop Android emulator after tests complete
./local-ci.sh --android --kill-emulator

# Get help
./local-ci.sh --help
```

#### NEW: Parallel Execution (40-50% Faster!)

Run iOS and Android simultaneously for significant speedup:

```bash
# Parallel execution (recommended for development)
./local-ci.sh --all --parallel

# Parallel with quick mode (fastest option - 1-2 min!)
./local-ci.sh --all --parallel --quick

# Parallel with verbose progress (shows test details)
./local-ci.sh --all --parallel --verbose

# Disable progress indicators (for cleaner logs)
./local-ci.sh --all --parallel --no-progress
```

**How Parallel Mode Works:**
- iOS and Android pipelines run simultaneously in background processes
- Both must complete before final results are shown
- Exit code reflects combined status (fails if either platform fails)
- **40-50% faster** than sequential mode
- Safe: Results are properly synchronized before final report

**When to Use Parallel:**
- ✅ Feature development (quick feedback loop)
- ✅ Before commits (pre-commit hook can use this)
- ✅ Rapid iteration cycles
- ✅ When both platforms need validation
- ❌ Debugging specific platform issues (use `--ios` or `--android`)
- ❌ When you need detailed real-time output from one platform

**Progress Indicators:**
- **Default Mode**: Spinner animations with elapsed time
- **Verbose Mode (`--verbose`)**: Adds live test counts and current test names
- **No Progress (`--no-progress`)**: Clean output without animations (useful for CI logs)

#### Android Emulator Management

The local CI now **automatically launches Android emulators** if none are running, matching GitHub Actions behavior!

**Features:**
- ✅ **Auto-detection**: Checks if emulator is already running
- ✅ **Auto-launch**: Starts an emulator automatically if needed
- ✅ **Permission Granting**: Automatically grants RECORD_AUDIO and MODIFY_AUDIO_SETTINGS
- ✅ **Smart Cleanup**: Optional flag to stop emulator after tests

**How it works:**
1. When running Android UI tests, CI checks for running emulator
2. If none found, automatically launches best available AVD
3. Waits for emulator to fully boot (5-minute timeout)
4. Grants required app permissions
5. Runs UI tests
6. Optionally stops emulator if `--kill-emulator` flag is set

**Manual Emulator Management:**
```bash
# Check emulator status
./scripts/android-emulator-manager.sh status

# Start emulator manually
./scripts/android-emulator-manager.sh start --wait --grant-permissions

# Grant permissions to running emulator
./scripts/android-emulator-manager.sh grant-permissions

# Stop emulator
./scripts/android-emulator-manager.sh stop
```

**When to use `--kill-emulator`:**
- ✅ Save resources after long test runs
- ✅ Clean slate for next test run
- ❌ Don't use if running multiple test iterations (keeps emulator warm)

#### What Gets Run

**Full Mode - Sequential** (`--all`):
- iOS: Build → Unit Tests → UI Tests
- Android: Build → Unit Tests → UI Tests (if emulator running)
- Duration: ~5-10 minutes
- Platforms run one after another

**Full Mode - Parallel** (`--all --parallel`):
- iOS & Android: Build → Unit Tests → UI Tests (simultaneously)
- Duration: ~3-6 minutes (40-50% faster!)
- Both platforms run at the same time
- Final results shown after both complete

**Quick Mode - Sequential** (`--all --quick`):
- iOS: Build → Unit Tests only
- Android: Build → Unit Tests only
- Duration: ~2-3 minutes

**Quick Mode - Parallel** (`--all --parallel --quick`):
- iOS & Android: Build → Unit Tests (simultaneously)
- Duration: ~1-2 minutes (fastest option!)
- Recommended for rapid development iteration

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

Colored output shows real-time progress with spinner animations:

**Sequential Mode (Default):**
```
🚀 Just Spent - Local CI Pipeline
================================

⠋ Building iOS app... [45s]
✅ iOS build completed (45s)

⠙ Running iOS unit tests... [2m 15s]
✅ iOS unit tests passed (2m 15s)

⠹ Running iOS UI tests... [1m 30s]
✅ iOS UI tests passed (1m 30s)

========================================
✅ All CI checks passed!
========================================
Total duration: 4m 30s
```

**Parallel Mode (40-50% Faster):**
```
🚀 Just Spent - Local CI Pipeline
================================
Execution: Parallel (40-50% faster)

Running iOS and Android pipelines in parallel...

[Both platforms run simultaneously]

Both pipelines completed

========================================
✅ All CI checks passed!
========================================
Total duration: 2m 45s (40% faster!)
```

**Verbose Mode (--verbose):**
Shows live test counts and current test names:
```
⠋ Running iOS unit tests... [1m 23s] - Tests: 45/80 (43 passed, 2 failed)
  Current: CurrencyFormatterTests.testFormatAED_withSymbolAndGroup...
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
├── report_20250129_143022.html           # HTML report
├── report_20250129_143022.json           # JSON results
├── ios_build_20250129_143022.log         # iOS build log
├── ios_unit_20250129_143022.log          # iOS unit test log
├── ios_ui_20250129_143022.log            # iOS UI test log
├── ios_unit_20250129_143022.xcresult     # iOS test results
├── android_build_20250129_143022.log     # Android build log
├── android_unit_20250129_143022.log      # Android unit test log
├── android_ui_20250129_143022.log        # Android UI test log
└── android_emulator_20250129_143022.log  # Android emulator management log
```

To view a log:
```bash
# View most recent iOS build log
cat .ci-results/ios_build_*.log | tail -n 50

# View most recent Android unit test log
cat .ci-results/android_unit_*.log | tail -n 50

# View Android emulator management log
cat .ci-results/android_emulator_*.log | tail -n 50

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

#### Android Emulator Issues

**NEW:** Local CI now auto-launches emulators! But if you encounter issues:

**Problem: "Failed to launch emulator"**

1. **Check if AVD exists**:
   ```bash
   # List available AVDs
   emulator -list-avds

   # Check emulator status
   ./scripts/android-emulator-manager.sh status
   ```

2. **Create AVD if missing**:
   - Open Android Studio
   - Go to Tools → Device Manager
   - Create Device
   - Recommended: Pixel 6, API 28+, Google APIs

3. **Manual emulator launch**:
   ```bash
   # Start emulator manually
   ./scripts/android-emulator-manager.sh start --wait --grant-permissions

   # Or use emulator command directly
   emulator -avd Pixel_9_Pro &
   ```

**Problem: "Emulator boot timeout"**

- Increase timeout in `scripts/android-emulator-manager.sh` (default: 5 minutes)
- Check emulator logs: `cat .ci-results/android_emulator_*.log`
- Try launching emulator manually first to see errors

**Problem: "Permission grant failed"**

- Permissions are granted automatically, but may fail if:
  - App not installed yet (build APK first)
  - Emulator not fully booted
  - ADB connection issues
- Grant manually: `./scripts/android-emulator-manager.sh grant-permissions`

**Problem: "Emulator won't stop"**

```bash
# Force kill emulator
adb emu kill

# Or find and kill process
ps aux | grep emulator
kill -9 <PID>
```

#### Slow Performance

If local CI is slower than expected, try these optimizations:

1. **Use parallel mode** (40-50% faster):
   ```bash
   ./local-ci.sh --all --parallel

   # Or combine with quick mode for maximum speed (1-2 min!)
   ./local-ci.sh --all --parallel --quick
   ```

2. **Use quick mode** during development:
   ```bash
   ./local-ci.sh --all --quick
   ```

3. **Run single platform** when working on one:
   ```bash
   ./local-ci.sh --ios     # When working on iOS
   ./local-ci.sh --android # When working on Android
   ```

4. **Skip UI tests** until needed:
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

| Metric | Local CI (Sequential) | Local CI (Parallel) | GitHub Actions |
|--------|----------------------|---------------------|----------------|
| **Full Suite** | 5-10 min | **3-6 min** ✨ | 11-12 min |
| **Quick Mode** | 2-3 min | **1-2 min** ✨ | N/A |
| **Network Required** | No | No | Yes |
| **Cost** | Free | Free | GitHub minutes |
| **Queue Time** | 0 sec | 0 sec | 30-60 sec |
| **Failure Rate** | ~5% | ~5% | ~10% |
| **Speedup** | Baseline | **40-50% faster** | - |

**Parallel Mode Highlights:**
- ✨ **3-6 min** for full suite (vs 5-10 min sequential)
- ✨ **1-2 min** for quick mode (vs 2-3 min sequential)
- 🚀 **40-50% faster** than sequential execution
- 💯 Same reliability as sequential mode
- 🎯 Recommended for development workflow

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
