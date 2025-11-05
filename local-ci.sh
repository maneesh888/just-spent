#!/bin/bash

# ============================================================================
# Just Spent - Local CI/CD Script
# ============================================================================
# This script runs the same checks as GitHub Actions but locally for faster
# feedback during development. Part of the hybrid CI/CD approach.
#
# Usage:
#   ./local-ci.sh [--ios] [--android] [--all] [--skip-ui] [--quick] [--kill-emulator]
#
# Options:
#   --ios            Run iOS checks only
#   --android        Run Android checks only
#   --all            Run both iOS and Android (default)
#   --skip-ui        Skip UI tests (faster, unit tests only)
#   --quick          Fast mode: build + unit tests only
#   --kill-emulator  Stop Android emulator after tests complete
#   --help           Show this help message
# ============================================================================

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/.ci-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$RESULTS_DIR/report_$TIMESTAMP.json"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Icons
ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_INFO="ℹ️ "
ICON_RUNNING="⏳"
ICON_SKIP="⏭️ "
ICON_INCOMPLETE="⚠️ "

# ============================================================================
# Expected Test Counts (Industry Standard: Validate Completeness)
# ============================================================================
# These values represent the minimum number of tests that MUST execute
# for a test suite to be considered "complete". If fewer tests run,
# the build FAILS (even if xcodebuild/gradle returns exit code 0).
#
# Industry Standard: A CI pipeline MUST fail if tests don't fully execute,
# even if the test tool returns success. Incomplete execution = FAILURE.
EXPECTED_IOS_UNIT_TESTS=80  # 83 total - 3 skipped (XCTSkip) - 1 excluded (simulator)
EXPECTED_ANDROID_UNIT_TESTS=145
# Note: UI test counts are dynamic (emulator-dependent), so no minimum enforced

# ============================================================================
# Parse Command Line Arguments
# ============================================================================
RUN_IOS=false
RUN_ANDROID=false
RUN_ALL=false
SKIP_UI_TESTS=false
QUICK_MODE=false
KILL_EMULATOR=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --ios)
      RUN_IOS=true
      shift
      ;;
    --android)
      RUN_ANDROID=true
      shift
      ;;
    --all)
      RUN_ALL=true
      shift
      ;;
    --skip-ui)
      SKIP_UI_TESTS=true
      shift
      ;;
    --quick)
      QUICK_MODE=true
      SKIP_UI_TESTS=true
      shift
      ;;
    --kill-emulator)
      KILL_EMULATOR=true
      shift
      ;;
    --help)
      head -n 20 "$0" | tail -n 17
      exit 0
      ;;
    *)
      echo -e "${RED}${ICON_ERROR} Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# If no platform specified, run all
if [ "$RUN_IOS" = false ] && [ "$RUN_ANDROID" = false ]; then
  RUN_ALL=true
fi

if [ "$RUN_ALL" = true ]; then
  RUN_IOS=true
  RUN_ANDROID=true
fi

# ============================================================================
# Helper Functions
# ============================================================================

# Print colored messages
success() {
  echo -e "${GREEN}${ICON_SUCCESS} $1${NC}"
}

error() {
  echo -e "${RED}${ICON_ERROR} $1${NC}"
}

info() {
  echo -e "${CYAN}${ICON_INFO}$1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

running() {
  echo -e "${BLUE}${ICON_RUNNING} $1${NC}"
}

skip() {
  echo -e "${YELLOW}${ICON_SKIP}$1${NC}"
}

section() {
  echo ""
  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${PURPLE}${BOLD}  $1${NC}"
  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Send macOS notification
notify() {
  local title="$1"
  local message="$2"
  local sound="${3:-Glass}"

  osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
}

# Timer functions
start_timer() {
  TIMER_START=$(date +%s)
}

end_timer() {
  TIMER_END=$(date +%s)
  ELAPSED=$((TIMER_END - TIMER_START))
  echo "$ELAPSED"
}

format_duration() {
  local seconds=$1
  local minutes=$((seconds / 60))
  local remaining_seconds=$((seconds % 60))

  if [ $minutes -gt 0 ]; then
    echo "${minutes}m ${remaining_seconds}s"
  else
    echo "${seconds}s"
  fi
}

# Global variables to store test results
IOS_BUILD_STATUS=""
IOS_BUILD_DURATION=0
IOS_UNIT_STATUS=""
IOS_UNIT_DURATION=0
IOS_UNIT_COUNT=0
IOS_UNIT_PASSED=0
IOS_UNIT_FAILED=0
IOS_UI_STATUS=""
IOS_UI_DURATION=0
IOS_UI_COUNT=0
IOS_UI_PASSED=0
IOS_UI_FAILED=0

ANDROID_BUILD_STATUS=""
ANDROID_BUILD_DURATION=0
ANDROID_UNIT_STATUS=""
ANDROID_UNIT_DURATION=0
ANDROID_UNIT_COUNT=0
ANDROID_UNIT_PASSED=0
ANDROID_UNIT_FAILED=0
ANDROID_UI_STATUS=""
ANDROID_UI_DURATION=0
ANDROID_UI_COUNT=0
ANDROID_UI_PASSED=0
ANDROID_UI_FAILED=0

# Initialize results directory
init_results() {
  mkdir -p "$RESULTS_DIR"
}

# Parse Gradle test output for test counts
parse_gradle_test_output() {
  local log_file=$1
  local test_type=${2:-"unit"}  # Default to "unit" if not specified
  local test_count=0
  local passed=0
  local failed=0

  # Gradle doesn't output test counts to console, so check XML results instead
  local test_results_dir
  if [ "$test_type" = "ui" ]; then
    # Android UI tests (instrumented tests) results location
    # Note: Results may be in connected/ or connected/debug/ subdirectory
    test_results_dir="$SCRIPT_DIR/android/app/build/outputs/androidTest-results/connected"
  else
    # Android unit tests results location
    test_results_dir="$SCRIPT_DIR/android/app/build/test-results/testDebugUnitTest"
  fi

  if [ -d "$test_results_dir" ]; then
    # Parse XML test results (search recursively for UI tests, direct for unit tests)
    if [ "$test_type" = "ui" ]; then
      # Use while loop with null delimiter to handle filenames with spaces
      while IFS= read -r -d '' xml_file; do
        if [ -f "$xml_file" ]; then
          # Extract test counts from XML: <testsuite tests="45" failures="0" errors="0"
          local suite_tests=$(grep '<testsuite' "$xml_file" | sed 's/.*tests="\([0-9]*\)".*/\1/' | head -1)
          local suite_failures=$(grep '<testsuite' "$xml_file" | sed 's/.*failures="\([0-9]*\)".*/\1/' | head -1)
          local suite_errors=$(grep '<testsuite' "$xml_file" | sed 's/.*errors="\([0-9]*\)".*/\1/' | head -1)

          [ -n "$suite_tests" ] && test_count=$((test_count + suite_tests))
          [ -n "$suite_failures" ] && failed=$((failed + suite_failures))
          [ -n "$suite_errors" ] && failed=$((failed + suite_errors))
        fi
      done < <(find "$test_results_dir" -name "*.xml" -type f -print0)
    else
      # Unit tests: use simple for loop (filenames don't have spaces)
      for xml_file in "$test_results_dir"/*.xml; do
        if [ -f "$xml_file" ]; then
          # Extract test counts from XML: <testsuite tests="45" failures="0" errors="0"
          local suite_tests=$(grep '<testsuite' "$xml_file" | sed 's/.*tests="\([0-9]*\)".*/\1/' | head -1)
          local suite_failures=$(grep '<testsuite' "$xml_file" | sed 's/.*failures="\([0-9]*\)".*/\1/' | head -1)
          local suite_errors=$(grep '<testsuite' "$xml_file" | sed 's/.*errors="\([0-9]*\)".*/\1/' | head -1)

          [ -n "$suite_tests" ] && test_count=$((test_count + suite_tests))
          [ -n "$suite_failures" ] && failed=$((failed + suite_failures))
          [ -n "$suite_errors" ] && failed=$((failed + suite_errors))
        fi
      done
    fi

    passed=$((test_count - failed))
  elif grep -q "BUILD SUCCESSFUL" "$log_file" 2>/dev/null; then
    # Check if tests actually ran by looking for the test task
    if grep -q "Task :app:testDebugUnitTest" "$log_file" 2>/dev/null; then
      # Tests ran but no XML results found (shouldn't happen with --rerun-tasks)
      test_count=0
    fi
  fi

  # Ensure we always return valid numbers (default to 0 if empty)
  # Strip any non-digit characters to ensure clean integers for JSON
  test_count=$(echo "${test_count:-0}" | tr -cd '0-9')
  passed=$(echo "${passed:-0}" | tr -cd '0-9')
  failed=$(echo "${failed:-0}" | tr -cd '0-9')

  # If empty after stripping, default to 0
  test_count=${test_count:-0}
  passed=${passed:-0}
  failed=${failed:-0}

  echo "$test_count:$passed:$failed"
}

# Parse xcodebuild test output for test counts
parse_xcodebuild_test_output() {
  local log_file=$1
  local test_count=0
  local passed=0
  local failed=0

  # Industry Standard: Parse actual test case results from xcodebuild output
  # xcodebuild outputs individual test cases in two formats:
  #   Unit tests:  "Test case 'MyTest.testSomething()' passed on 'iPhone 16'"
  #   UI tests:    "Test Case '-[MyUITest testSomething]' passed (3.286 seconds)."

  if [ -f "$log_file" ]; then
    # Count test cases that passed (case-insensitive, works for both unit and UI tests)
    passed_raw=$(grep -ci "Test [Cc]ase .* passed" "$log_file" 2>/dev/null)
    passed=$(echo "$passed_raw" | tr -cd '0-9')
    passed=${passed:-0}

    # Count test cases that failed (case-insensitive)
    failed_raw=$(grep -ci "Test [Cc]ase .* failed" "$log_file" 2>/dev/null)
    failed=$(echo "$failed_raw" | tr -cd '0-9')
    failed=${failed:-0}

    # Total = passed + failed (skipped tests don't count toward execution)
    test_count=$((passed + failed))
  fi

  # Ensure we always return valid numbers (default to 0 if empty)
  test_count=${test_count:-0}
  passed=${passed:-0}
  failed=${failed:-0}

  echo "$test_count:$passed:$failed"
}

# Record a test result
record_test_result() {
  local platform=$1  # "ios" or "android"
  local test_type=$2 # "build", "unit", "ui"
  local status=$3    # "pass", "fail", "skip", "no_tests"
  local duration=$4  # in seconds
  local test_count=${5:-0}   # total tests
  local passed=${6:-0}       # passed tests
  local failed=${7:-0}       # failed tests

  # Store in global variables
  if [ "$platform" = "ios" ]; then
    if [ "$test_type" = "build" ]; then
      IOS_BUILD_STATUS="$status"
      IOS_BUILD_DURATION="$duration"
    elif [ "$test_type" = "unit" ]; then
      IOS_UNIT_STATUS="$status"
      IOS_UNIT_DURATION="$duration"
      IOS_UNIT_COUNT="$test_count"
      IOS_UNIT_PASSED="$passed"
      IOS_UNIT_FAILED="$failed"
    elif [ "$test_type" = "ui" ]; then
      IOS_UI_STATUS="$status"
      IOS_UI_DURATION="$duration"
      IOS_UI_COUNT="$test_count"
      IOS_UI_PASSED="$passed"
      IOS_UI_FAILED="$failed"
    fi
  else
    if [ "$test_type" = "build" ]; then
      ANDROID_BUILD_STATUS="$status"
      ANDROID_BUILD_DURATION="$duration"
    elif [ "$test_type" = "unit" ]; then
      ANDROID_UNIT_STATUS="$status"
      ANDROID_UNIT_DURATION="$duration"
      ANDROID_UNIT_COUNT="$test_count"
      ANDROID_UNIT_PASSED="$passed"
      ANDROID_UNIT_FAILED="$failed"
    elif [ "$test_type" = "ui" ]; then
      ANDROID_UI_STATUS="$status"
      ANDROID_UI_DURATION="$duration"
      ANDROID_UI_COUNT="$test_count"
      ANDROID_UI_PASSED="$passed"
      ANDROID_UI_FAILED="$failed"
    fi
  fi
}

# Finalize results file
finalize_results() {
  local success=$1

  # Build iOS JSON section
  local ios_json=""
  if [ -n "$IOS_BUILD_STATUS" ]; then
    ios_json="\"build\": {\"status\": \"$IOS_BUILD_STATUS\", \"duration\": $IOS_BUILD_DURATION}"
  fi
  if [ -n "$IOS_UNIT_STATUS" ]; then
    [ -n "$ios_json" ] && ios_json="$ios_json,"
    ios_json="$ios_json
      \"unit\": {\"status\": \"$IOS_UNIT_STATUS\", \"duration\": $IOS_UNIT_DURATION, \"count\": $IOS_UNIT_COUNT, \"passed\": $IOS_UNIT_PASSED, \"failed\": $IOS_UNIT_FAILED}"
  fi
  if [ -n "$IOS_UI_STATUS" ]; then
    [ -n "$ios_json" ] && ios_json="$ios_json,"
    ios_json="$ios_json
      \"ui\": {\"status\": \"$IOS_UI_STATUS\", \"duration\": $IOS_UI_DURATION, \"count\": $IOS_UI_COUNT, \"passed\": $IOS_UI_PASSED, \"failed\": $IOS_UI_FAILED}"
  fi

  # Build Android JSON section
  local android_json=""
  if [ -n "$ANDROID_BUILD_STATUS" ]; then
    android_json="\"build\": {\"status\": \"$ANDROID_BUILD_STATUS\", \"duration\": $ANDROID_BUILD_DURATION}"
  fi
  if [ -n "$ANDROID_UNIT_STATUS" ]; then
    [ -n "$android_json" ] && android_json="$android_json,"
    android_json="$android_json
      \"unit\": {\"status\": \"$ANDROID_UNIT_STATUS\", \"duration\": $ANDROID_UNIT_DURATION, \"count\": $ANDROID_UNIT_COUNT, \"passed\": $ANDROID_UNIT_PASSED, \"failed\": $ANDROID_UNIT_FAILED}"
  fi
  if [ -n "$ANDROID_UI_STATUS" ]; then
    [ -n "$android_json" ] && android_json="$android_json,"
    android_json="$android_json
      \"ui\": {\"status\": \"$ANDROID_UI_STATUS\", \"duration\": $ANDROID_UI_DURATION, \"count\": $ANDROID_UI_COUNT, \"passed\": $ANDROID_UI_PASSED, \"failed\": $ANDROID_UI_FAILED}"
  fi

  # Write JSON file
  cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "results": {
    "ios": {
      $ios_json
    },
    "android": {
      $android_json
    }
  },
  "overall_success": $success,
  "duration": $TOTAL_DURATION
}
EOF
}

# ============================================================================
# iOS Pipeline Functions
# ============================================================================

# Grant iOS simulator permissions for testing
grant_ios_simulator_permissions() {
  local simulator_name="$1"
  local bundle_id="com.justspent.app"

  info "Granting iOS simulator permissions..."

  # Get simulator ID
  local simulator_id=$(xcrun simctl list devices | grep "$simulator_name" | grep -v "unavailable" | head -n 1 | grep -oE '\([A-Z0-9-]+\)' | tr -d '()')

  if [ -z "$simulator_id" ]; then
    warning "Could not find simulator ID for '$simulator_name'"
    return 1
  fi

  # Boot simulator if not already booted
  local sim_state=$(xcrun simctl list devices | grep "$simulator_id" | grep -o "Booted\|Shutdown" || echo "Shutdown")
  if [ "$sim_state" != "Booted" ]; then
    info "Booting simulator..."
    xcrun simctl boot "$simulator_id" 2>/dev/null || true
    sleep 5  # Wait for simulator to boot
  fi

  # Grant microphone permission
  xcrun simctl privacy "$simulator_id" grant microphone "$bundle_id" 2>/dev/null || true

  # Grant speech recognition permission
  xcrun simctl privacy "$simulator_id" grant speech-recognition "$bundle_id" 2>/dev/null || true

  success "iOS simulator permissions granted (microphone + speech recognition)"
}

run_ios_pipeline() {
  section "iOS Pipeline"

  local ios_success=true
  local ios_start=$(date +%s)

  cd "$SCRIPT_DIR/ios/JustSpent"

  # iOS Build
  running "Building iOS app..."
  start_timer
  if xcodebuild clean build \
    -project JustSpent.xcodeproj \
    -scheme JustSpent \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -configuration Debug \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    > "$RESULTS_DIR/ios_build_$TIMESTAMP.log" 2>&1; then

    local build_time=$(end_timer)
    success "iOS build completed ($(format_duration $build_time))"
    record_test_result "ios" "build" "pass" "$build_time"
  else
    local build_time=$(end_timer)
    error "iOS build failed ($(format_duration $build_time))"
    error "Check log: $RESULTS_DIR/ios_build_$TIMESTAMP.log"
    record_test_result "ios" "build" "fail" "$build_time"
    ios_success=false
    cd "$SCRIPT_DIR"
    return 1
  fi

  # Grant simulator permissions before running tests
  grant_ios_simulator_permissions "iPhone 16"

  # iOS Unit Tests
  running "Running iOS unit tests..."
  start_timer
  if xcodebuild test \
    -project JustSpent.xcodeproj \
    -scheme JustSpent \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:JustSpentTests \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULTS_DIR/ios_unit_$TIMESTAMP.xcresult" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    > "$RESULTS_DIR/ios_unit_$TIMESTAMP.log" 2>&1; then

    local test_time=$(end_timer)

    # Parse test output for counts
    local test_results=$(parse_xcodebuild_test_output "$RESULTS_DIR/ios_unit_$TIMESTAMP.log")
    local test_count=$(echo "$test_results" | cut -d':' -f1)
    local test_passed=$(echo "$test_results" | cut -d':' -f2)
    local test_failed=$(echo "$test_results" | cut -d':' -f3)

    # Industry Standard: Validate test completeness
    # Even if xcodebuild returns success, we must verify all expected tests ran
    if [ "$test_count" -eq 0 ]; then
      error "iOS unit tests: No tests found!"
      info "Expected: $EXPECTED_IOS_UNIT_TESTS tests, Found: 0"
      record_test_result "ios" "unit" "no_tests" "$test_time" "$test_count" "$test_passed" "$test_failed"
      ios_success=false
    elif [ "$test_count" -lt "$EXPECTED_IOS_UNIT_TESTS" ]; then
      # INCOMPLETE: Some tests ran, but not all (simulator crash, etc.)
      error "${ICON_INCOMPLETE}iOS unit tests INCOMPLETE - not all tests executed"
      error "Expected: $EXPECTED_IOS_UNIT_TESTS tests, Executed: $test_count tests"
      info "Tests: $test_count executed, $test_passed passed, $test_failed failed"
      info "Missing: $((EXPECTED_IOS_UNIT_TESTS - test_count)) tests did not run"
      error "This usually indicates simulator crash or test timeout"
      record_test_result "ios" "unit" "incomplete" "$test_time" "$test_count" "$test_passed" "$test_failed"
      ios_success=false
    elif [ "$test_failed" -gt 0 ]; then
      # FAILURE: All tests ran, but some failed
      error "iOS unit tests FAILED"
      info "Tests: $test_count executed, $test_passed passed, $test_failed failed"
      record_test_result "ios" "unit" "fail" "$test_time" "$test_count" "$test_passed" "$test_failed"
      ios_success=false
    else
      # SUCCESS: All tests executed and passed
      success "iOS unit tests passed ($(format_duration $test_time))"
      info "Tests: $test_count/$EXPECTED_IOS_UNIT_TESTS executed, $test_passed passed, $test_failed failed"
      record_test_result "ios" "unit" "pass" "$test_time" "$test_count" "$test_passed" "$test_failed"
    fi
  else
    local test_time=$(end_timer)

    # Parse test output even on failure
    local test_results=$(parse_xcodebuild_test_output "$RESULTS_DIR/ios_unit_$TIMESTAMP.log")
    local test_count=$(echo "$test_results" | cut -d':' -f1)
    local test_passed=$(echo "$test_results" | cut -d':' -f2)
    local test_failed=$(echo "$test_results" | cut -d':' -f3)

    # Industry Standard: Check if incomplete vs regular failure
    if [ "$test_count" -lt "$EXPECTED_IOS_UNIT_TESTS" ]; then
      # INCOMPLETE: Not all tests executed (some passed, some failed, but missing tests)
      error "${ICON_INCOMPLETE}iOS unit tests INCOMPLETE - not all tests executed"
      error "Expected: $EXPECTED_IOS_UNIT_TESTS tests, Executed: $test_count tests"
      info "Tests: $test_count executed, $test_passed passed, $test_failed failed"
      info "Missing: $((EXPECTED_IOS_UNIT_TESTS - test_count)) tests did not run"
      error "This usually indicates simulator crash, timeout, or skipped tests"
      error "Check log: $RESULTS_DIR/ios_unit_$TIMESTAMP.log"
      record_test_result "ios" "unit" "incomplete" "$test_time" "$test_count" "$test_passed" "$test_failed"
    else
      # FAILURE: All tests executed, but some failed
      error "iOS unit tests FAILED ($(format_duration $test_time))"
      info "Tests: $test_count/$EXPECTED_IOS_UNIT_TESTS executed, $test_passed passed, $test_failed failed"
      error "Check log: $RESULTS_DIR/ios_unit_$TIMESTAMP.log"
      record_test_result "ios" "unit" "fail" "$test_time" "$test_count" "$test_passed" "$test_failed"
    fi

    ios_success=false
  fi

  # iOS UI Tests
  # Grant permissions before UI tests (microphone access required)
  grant_ios_simulator_permissions "iPhone 16"

  if [ "$SKIP_UI_TESTS" = false ]; then
    running "Running iOS UI tests..."
    start_timer
    if xcodebuild test \
      -project JustSpent.xcodeproj \
      -scheme JustSpent \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -only-testing:JustSpentUITests \
      -parallel-testing-enabled NO \
      -enableCodeCoverage YES \
      -resultBundlePath "$RESULTS_DIR/ios_ui_$TIMESTAMP.xcresult" \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      > "$RESULTS_DIR/ios_ui_$TIMESTAMP.log" 2>&1; then

      local test_time=$(end_timer)

      # Parse test output for counts
      local test_results=$(parse_xcodebuild_test_output "$RESULTS_DIR/ios_ui_$TIMESTAMP.log")
      local test_count=$(echo "$test_results" | cut -d':' -f1)
      local test_passed=$(echo "$test_results" | cut -d':' -f2)
      local test_failed=$(echo "$test_results" | cut -d':' -f3)

      if [ "$test_count" -eq 0 ]; then
        warning "iOS UI tests: No tests found!"
        info "Tests: $test_count total"
        record_test_result "ios" "ui" "no_tests" "$test_time" "$test_count" "$test_passed" "$test_failed"
      else
        success "iOS UI tests passed ($(format_duration $test_time))"
        info "Tests: $test_count total, $test_passed passed, $test_failed failed"
        record_test_result "ios" "ui" "pass" "$test_time" "$test_count" "$test_passed" "$test_failed"
      fi
    else
      local test_time=$(end_timer)
      error "iOS UI tests failed ($(format_duration $test_time))"
      error "Check log: $RESULTS_DIR/ios_ui_$TIMESTAMP.log"

      # Parse test output even on failure
      local test_results=$(parse_xcodebuild_test_output "$RESULTS_DIR/ios_ui_$TIMESTAMP.log")
      local test_count=$(echo "$test_results" | cut -d':' -f1)
      local test_passed=$(echo "$test_results" | cut -d':' -f2)
      local test_failed=$(echo "$test_results" | cut -d':' -f3)

      info "Tests: $test_count total, $test_passed passed, $test_failed failed"
      record_test_result "ios" "ui" "fail" "$test_time" "$test_count" "$test_passed" "$test_failed"
      ios_success=false
    fi
  else
    skip "iOS UI tests skipped (--skip-ui flag)"
    record_test_result "ios" "ui" "skip" "0" "0" "0" "0"
  fi

  cd "$SCRIPT_DIR"

  local ios_end=$(date +%s)
  local ios_duration=$((ios_end - ios_start))

  if [ "$ios_success" = true ]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Android Pipeline Functions
# ============================================================================

run_android_pipeline() {
  section "Android Pipeline"

  local android_success=true
  local android_start=$(date +%s)

  cd "$SCRIPT_DIR/android"

  # Grant execute permission
  chmod +x gradlew

  # Android Build
  running "Building Android app..."
  start_timer
  if ./gradlew assembleDebug --stacktrace \
    > "$RESULTS_DIR/android_build_$TIMESTAMP.log" 2>&1; then

    local build_time=$(end_timer)
    success "Android build completed ($(format_duration $build_time))"
    record_test_result "android" "build" "pass" "$build_time"
  else
    local build_time=$(end_timer)
    error "Android build failed ($(format_duration $build_time))"
    error "Check log: $RESULTS_DIR/android_build_$TIMESTAMP.log"
    record_test_result "android" "build" "fail" "$build_time"
    android_success=false
    cd "$SCRIPT_DIR"
    return 1
  fi

  # Android Unit Tests
  running "Running Android unit tests..."
  start_timer
  if ./gradlew testDebugUnitTest --rerun-tasks --stacktrace \
    > "$RESULTS_DIR/android_unit_$TIMESTAMP.log" 2>&1; then

    local test_time=$(end_timer)

    # Parse test output for counts
    local test_results=$(parse_gradle_test_output "$RESULTS_DIR/android_unit_$TIMESTAMP.log")
    local test_count=$(echo "$test_results" | cut -d':' -f1)
    local test_passed=$(echo "$test_results" | cut -d':' -f2)
    local test_failed=$(echo "$test_results" | cut -d':' -f3)

    # Industry Standard: Validate test completeness
    # Even if gradle returns success, we must verify all expected tests ran
    if [ "$test_count" -eq 0 ]; then
      error "Android unit tests: No tests found!"
      info "Expected: $EXPECTED_ANDROID_UNIT_TESTS tests, Found: 0"
      record_test_result "android" "unit" "no_tests" "$test_time" "$test_count" "$test_passed" "$test_failed"
      android_success=false
    elif [ "$test_count" -lt "$EXPECTED_ANDROID_UNIT_TESTS" ]; then
      # INCOMPLETE: Some tests ran, but not all
      error "${ICON_INCOMPLETE}Android unit tests INCOMPLETE - not all tests executed"
      error "Expected: $EXPECTED_ANDROID_UNIT_TESTS tests, Executed: $test_count tests"
      info "Tests: $test_count executed, $test_passed passed, $test_failed failed"
      info "Missing: $((EXPECTED_ANDROID_UNIT_TESTS - test_count)) tests did not run"
      error "This usually indicates test filtering or compilation issues"
      record_test_result "android" "unit" "incomplete" "$test_time" "$test_count" "$test_passed" "$test_failed"
      android_success=false
    elif [ "$test_failed" -gt 0 ]; then
      # FAILURE: All tests ran, but some failed
      error "Android unit tests FAILED"
      info "Tests: $test_count executed, $test_passed passed, $test_failed failed"
      record_test_result "android" "unit" "fail" "$test_time" "$test_count" "$test_passed" "$test_failed"
      android_success=false
    else
      # SUCCESS: All tests executed and passed
      success "Android unit tests passed ($(format_duration $test_time))"
      info "Tests: $test_count/$EXPECTED_ANDROID_UNIT_TESTS executed, $test_passed passed, $test_failed failed"
      record_test_result "android" "unit" "pass" "$test_time" "$test_count" "$test_passed" "$test_failed"
    fi
  else
    local test_time=$(end_timer)

    # Parse test output even on failure
    local test_results=$(parse_gradle_test_output "$RESULTS_DIR/android_unit_$TIMESTAMP.log")
    local test_count=$(echo "$test_results" | cut -d':' -f1)
    local test_passed=$(echo "$test_results" | cut -d':' -f2)
    local test_failed=$(echo "$test_results" | cut -d':' -f3)

    # Industry Standard: Check if incomplete vs regular failure
    if [ "$test_count" -lt "$EXPECTED_ANDROID_UNIT_TESTS" ]; then
      # INCOMPLETE: Not all tests executed (some passed, some failed, but missing tests)
      error "${ICON_INCOMPLETE}Android unit tests INCOMPLETE - not all tests executed"
      error "Expected: $EXPECTED_ANDROID_UNIT_TESTS tests, Executed: $test_count tests"
      info "Tests: $test_count executed, $test_passed passed, $test_failed failed"
      info "Missing: $((EXPECTED_ANDROID_UNIT_TESTS - test_count)) tests did not run"
      error "This usually indicates compilation issues or test filtering"
      error "Check log: $RESULTS_DIR/android_unit_$TIMESTAMP.log"
      record_test_result "android" "unit" "incomplete" "$test_time" "$test_count" "$test_passed" "$test_failed"
    else
      # FAILURE: All tests executed, but some failed
      error "Android unit tests FAILED ($(format_duration $test_time))"
      info "Tests: $test_count/$EXPECTED_ANDROID_UNIT_TESTS executed, $test_passed passed, $test_failed failed"
      error "Check log: $RESULTS_DIR/android_unit_$TIMESTAMP.log"
      record_test_result "android" "unit" "fail" "$test_time" "$test_count" "$test_passed" "$test_failed"
    fi

    android_success=false
  fi

  # Android UI Tests (with automatic emulator management)
  if [ "$SKIP_UI_TESTS" = false ]; then
    local emulator_was_started=false

    # Check if emulator is running, start if needed
    if ! adb devices 2>/dev/null | grep -q "device$"; then
      running "No emulator detected, launching automatically..."

      # Use emulator manager to start emulator
      if "$SCRIPT_DIR/scripts/android-emulator-manager.sh" start --wait --grant-permissions \
        > "$RESULTS_DIR/android_emulator_$TIMESTAMP.log" 2>&1; then

        success "Emulator launched and ready"
        emulator_was_started=true
      else
        error "Failed to launch emulator"
        error "Check log: $RESULTS_DIR/android_emulator_$TIMESTAMP.log"
        warning "Android UI tests skipped (emulator launch failed)"
        warning "You can manually start an emulator and re-run tests"
        # Don't fail the whole pipeline, just skip UI tests
        cd "$SCRIPT_DIR"
        return 0
      fi
    else
      info "Emulator already running, granting permissions..."

      # Grant permissions to existing emulator
      if "$SCRIPT_DIR/scripts/android-emulator-manager.sh" grant-permissions \
        >> "$RESULTS_DIR/android_emulator_$TIMESTAMP.log" 2>&1; then

        success "Permissions granted"
      else
        warning "Failed to grant some permissions (may not affect tests)"
      fi
    fi

    # Run UI tests
    running "Running Android UI tests..."
    start_timer
    if ./gradlew connectedDebugAndroidTest --rerun-tasks --stacktrace \
      > "$RESULTS_DIR/android_ui_$TIMESTAMP.log" 2>&1; then

      local test_time=$(end_timer)

      # Parse test output for counts
      local test_results=$(parse_gradle_test_output "$RESULTS_DIR/android_ui_$TIMESTAMP.log" "ui")
      local test_count=$(echo "$test_results" | cut -d':' -f1)
      local test_passed=$(echo "$test_results" | cut -d':' -f2)
      local test_failed=$(echo "$test_results" | cut -d':' -f3)

      if [ "$test_count" -eq 0 ]; then
        warning "Android UI tests: No tests found!"
        info "Tests: $test_count total"
        record_test_result "android" "ui" "no_tests" "$test_time" "$test_count" "$test_passed" "$test_failed"
      else
        success "Android UI tests passed ($(format_duration $test_time))"
        info "Tests: $test_count total, $test_passed passed, $test_failed failed"
        record_test_result "android" "ui" "pass" "$test_time" "$test_count" "$test_passed" "$test_failed"
      fi
    else
      local test_time=$(end_timer)
      error "Android UI tests failed ($(format_duration $test_time))"
      error "Check log: $RESULTS_DIR/android_ui_$TIMESTAMP.log"

      # Parse test output even on failure
      local test_results=$(parse_gradle_test_output "$RESULTS_DIR/android_ui_$TIMESTAMP.log" "ui")
      local test_count=$(echo "$test_results" | cut -d':' -f1)
      local test_passed=$(echo "$test_results" | cut -d':' -f2)
      local test_failed=$(echo "$test_results" | cut -d':' -f3)

      info "Tests: $test_count total, $test_passed passed, $test_failed failed"
      record_test_result "android" "ui" "fail" "$test_time" "$test_count" "$test_passed" "$test_failed"
      android_success=false
    fi

    # Kill emulator if requested and we started it
    if [ "$KILL_EMULATOR" = true ] && [ "$emulator_was_started" = true ]; then
      info "Stopping emulator (--kill-emulator flag set)..."
      "$SCRIPT_DIR/scripts/android-emulator-manager.sh" stop \
        >> "$RESULTS_DIR/android_emulator_$TIMESTAMP.log" 2>&1 || true
      success "Emulator stopped"
    fi
  else
    skip "Android UI tests skipped (--skip-ui flag)"
    record_test_result "android" "ui" "skip" "0"
  fi

  cd "$SCRIPT_DIR"

  local android_end=$(date +%s)
  local android_duration=$((android_end - android_start))

  if [ "$android_success" = true ]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Main Execution
# ============================================================================

# Print header
clear
echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
echo -e "${BOLD}${CYAN}║          🚀 Just Spent - Local CI Pipeline 🚀             ║${NC}"
echo -e "${BOLD}${CYAN}║                                                            ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

info "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
if [ "$QUICK_MODE" = true ]; then
  info "Mode: Quick (build + unit tests only)"
elif [ "$SKIP_UI_TESTS" = true ]; then
  info "Mode: Skip UI tests"
else
  info "Mode: Full (build + unit tests + UI tests)"
fi
echo ""

# Initialize results
init_results

# Start total timer
TOTAL_START=$(date +%s)

# Track overall success
OVERALL_SUCCESS=true

# Run iOS pipeline
if [ "$RUN_IOS" = true ]; then
  if ! run_ios_pipeline; then
    OVERALL_SUCCESS=false
  fi
fi

# Run Android pipeline
if [ "$RUN_ANDROID" = true ]; then
  if ! run_android_pipeline; then
    OVERALL_SUCCESS=false
  fi
fi

# Calculate total duration
TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))

# Finalize results
if [ "$OVERALL_SUCCESS" = true ]; then
  finalize_results "true"
else
  finalize_results "false"
fi

# Print final summary
section "Summary"

if [ "$OVERALL_SUCCESS" = true ]; then
  echo ""
  echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}${BOLD}║                                                            ║${NC}"
  echo -e "${GREEN}${BOLD}║               ✅ All CI Checks Passed! ✅                  ║${NC}"
  echo -e "${GREEN}${BOLD}║                                                            ║${NC}"
  echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  success "Total duration: $(format_duration $TOTAL_DURATION)"
  echo ""

  # Send success notification
  notify "Just Spent CI" "✅ All checks passed! ($(format_duration $TOTAL_DURATION))" "Glass"

  # Generate HTML report
  info "Generating HTML report..."
  if [ -f "$SCRIPT_DIR/scripts/generate-report.sh" ]; then
    "$SCRIPT_DIR/scripts/generate-report.sh" "$REPORT_FILE"
  fi

  exit 0
else
  echo ""
  echo -e "${RED}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}${BOLD}║                                                            ║${NC}"
  echo -e "${RED}${BOLD}║               ❌ CI Checks Failed ❌                       ║${NC}"
  echo -e "${RED}${BOLD}║                                                            ║${NC}"
  echo -e "${RED}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  error "Total duration: $(format_duration $TOTAL_DURATION)"
  error "Check logs in: $RESULTS_DIR"
  echo ""

  # Send failure notification
  notify "Just Spent CI" "❌ CI checks failed! Check terminal for details." "Basso"

  # Generate HTML report
  info "Generating HTML report..."
  if [ -f "$SCRIPT_DIR/scripts/generate-report.sh" ]; then
    "$SCRIPT_DIR/scripts/generate-report.sh" "$REPORT_FILE"
  fi

  exit 1
fi
