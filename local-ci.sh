#!/bin/bash

# ============================================================================
# Just Spent - Local CI/CD Script
# ============================================================================
# This script runs the same checks as GitHub Actions but locally for faster
# feedback during development. Part of the hybrid CI/CD approach.
#
# Usage:
#   ./local-ci.sh [--ios] [--android] [--all] [--skip-ui] [--quick] [--kill-emulator] [--parallel] [--verbose] [--no-progress]
#
# Options:
#   --ios            Run iOS checks only
#   --android        Run Android checks only
#   --all            Run both iOS and Android (default)
#   --skip-ui        Skip UI tests (faster, unit tests only)
#   --quick          Fast mode: build + unit tests only
#   --kill-emulator  Stop Android emulator after tests complete
#   --parallel       Run iOS and Android simultaneously (40-50% faster)
#   --verbose        Show detailed progress including current test names
#   --no-progress    Disable progress indicators (spinners, counters)
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
PARALLEL_MODE=false
VERBOSE_MODE=false
SHOW_PROGRESS=true

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
    --parallel)
      PARALLEL_MODE=true
      shift
      ;;
    --verbose)
      VERBOSE_MODE=true
      shift
      ;;
    --no-progress)
      SHOW_PROGRESS=false
      shift
      ;;
    --help)
      head -n 22 "$0" | tail -n 19
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

# Progress indicator with spinner
show_progress() {
  local pid=$1
  local message=$2
  local log_file=${3:-}
  local test_type=${4:-}

  if [ "$SHOW_PROGRESS" = false ]; then
    # Just wait for the process to finish without showing progress
    wait "$pid" 2>/dev/null
    return $?
  fi

  local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local elapsed=0
  local test_count=0
  local test_passed=0

  while kill -0 "$pid" 2>/dev/null; do
    for i in $(seq 0 9); do
      # Check if process still running
      if ! kill -0 "$pid" 2>/dev/null; then
        break 2
      fi

      # Show spinner with elapsed time
      local spinner_char="${spinner:$i:1}"
      local status_line="\r${spinner_char} ${message} [$(format_duration $elapsed)]"

      # Add test count if log file provided and verbose mode
      if [ -n "$log_file" ] && [ -f "$log_file" ] && [ "$VERBOSE_MODE" = true ]; then
        if [ "$test_type" = "xcode" ]; then
          # Parse iOS test progress
          test_passed=$(grep -ci "Test [Cc]ase .* passed" "$log_file" 2>/dev/null || echo "0")
          local test_failed=$(grep -ci "Test [Cc]ase .* failed" "$log_file" 2>/dev/null || echo "0")
          test_count=$((test_passed + test_failed))

          if [ "$test_count" -gt 0 ]; then
            status_line="${status_line} - Tests: ${test_count} (${test_passed} passed, ${test_failed} failed)"
          fi

          # Show current test name
          local current_test=$(tail -5 "$log_file" 2>/dev/null | grep -o "Test Case .* started" | tail -1 | sed 's/Test Case //' | sed 's/ started//' || echo "")
          if [ -n "$current_test" ]; then
            # Truncate long test names
            current_test=$(echo "$current_test" | cut -c1-50)
            status_line="${status_line}\n  Current: ${current_test}"
          fi
        elif [ "$test_type" = "gradle" ]; then
          # Parse Android test progress from XML results
          # (Gradle doesn't output real-time test info to console)
          local test_results_dir="$SCRIPT_DIR/android/app/build/test-results/testDebugUnitTest"
          if [ -d "$test_results_dir" ]; then
            test_count=$(find "$test_results_dir" -name "*.xml" -type f -exec grep -h '<testsuite' {} \; 2>/dev/null | sed 's/.*tests="\([0-9]*\)".*/\1/' | awk '{sum+=$1} END {print sum}' || echo "0")
            if [ "$test_count" -gt 0 ]; then
              status_line="${status_line} - Tests completed: ${test_count}"
            fi
          fi
        fi
      fi

      echo -ne "${status_line}"
      sleep 0.1
      elapsed=$((elapsed + 1))
    done
    elapsed=$((elapsed / 10))  # Adjust for the 10 iterations
  done

  # Clear the line and show completion
  echo -ne "\r$(printf ' %.0s' {1..100})\r"

  # Wait for process and return its exit code
  wait "$pid" 2>/dev/null
  return $?
}

# Display parallel status for both platforms
show_parallel_status() {
  local ios_phase=$1
  local android_phase=$2
  local ios_elapsed=$3
  local android_elapsed=$4

  if [ "$SHOW_PROGRESS" = false ]; then
    return
  fi

  # Clear screen section
  echo -ne "\033[2K\r"

  # Box drawing
  echo -e "${CYAN}┌─────────────────────────────┬─────────────────────────────┐${NC}"
  echo -e "${CYAN}│${NC} ${BLUE}iOS Pipeline${NC}                │ ${BLUE}Android Pipeline${NC}            │"
  echo -e "${CYAN}├─────────────────────────────┼─────────────────────────────┤${NC}"

  # iOS status
  local ios_status_line="│ ${ios_phase}"
  printf "%-60s│\n" "$ios_status_line"

  # Android status
  local android_status_line="│ ${android_phase}"
  printf "%-60s│\n" "$android_status_line"

  echo -e "${CYAN}└─────────────────────────────┴─────────────────────────────┘${NC}"
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

# Display execution mode
if [ "$QUICK_MODE" = true ]; then
  info "Test Mode: Quick (build + unit tests only)"
elif [ "$SKIP_UI_TESTS" = true ]; then
  info "Test Mode: Skip UI tests"
else
  info "Test Mode: Full (build + unit tests + UI tests)"
fi

# Display execution strategy
if [ "$PARALLEL_MODE" = true ]; then
  info "Execution: Parallel (40-50% faster)"
else
  info "Execution: Sequential (default)"
fi

# Display progress settings
if [ "$SHOW_PROGRESS" = true ]; then
  if [ "$VERBOSE_MODE" = true ]; then
    info "Progress: Enabled (verbose with test details)"
  else
    info "Progress: Enabled (spinners and counters)"
  fi
else
  info "Progress: Disabled"
fi

echo ""

# Initialize results
init_results

# Start total timer
TOTAL_START=$(date +%s)

# Track overall success
OVERALL_SUCCESS=true

# Run pipelines (parallel or sequential based on flag)
if [ "$PARALLEL_MODE" = true ] && [ "$RUN_IOS" = true ] && [ "$RUN_ANDROID" = true ]; then
  # ========================================================================
  # Parallel Execution Mode (40-50% faster)
  # ========================================================================
  info "Running iOS and Android pipelines in parallel..."
  echo ""

  # Create temp files to store exit codes and results
  IOS_EXIT_FILE=$(mktemp)
  ANDROID_EXIT_FILE=$(mktemp)
  IOS_OUTPUT_FILE=$(mktemp)
  ANDROID_OUTPUT_FILE=$(mktemp)

  # Run iOS in background (redirect output to temp file)
  (
    if run_ios_pipeline > "$IOS_OUTPUT_FILE" 2>&1; then
      echo "0" > "$IOS_EXIT_FILE"
    else
      echo "1" > "$IOS_EXIT_FILE"
    fi
  ) &
  IOS_PID=$!

  # Run Android in background (redirect output to temp file)
  (
    if run_android_pipeline > "$ANDROID_OUTPUT_FILE" 2>&1; then
      echo "0" > "$ANDROID_EXIT_FILE"
    else
      echo "1" > "$ANDROID_EXIT_FILE"
    fi
  ) &
  ANDROID_PID=$!

  # Show progress while waiting
  if [ "$SHOW_PROGRESS" = true ]; then
    local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local elapsed=0
    while kill -0 $IOS_PID 2>/dev/null || kill -0 $ANDROID_PID 2>/dev/null; do
      for i in $(seq 0 9); do
        if ! kill -0 $IOS_PID 2>/dev/null && ! kill -0 $ANDROID_PID 2>/dev/null; then
          break 2
        fi
        local spinner_char="${spinner:$i:1}"
        echo -ne "\r${spinner_char} Running both platforms in parallel... [$(format_duration $elapsed)]"
        sleep 0.1
        elapsed=$((elapsed + 1))
      done
      elapsed=$((elapsed / 10))
    done
    echo -ne "\r$(printf ' %.0s' {1..100})\r"
  fi

  # Wait for both to complete
  wait $IOS_PID 2>/dev/null
  IOS_RESULT=$(cat "$IOS_EXIT_FILE" 2>/dev/null || echo "1")

  wait $ANDROID_PID 2>/dev/null
  ANDROID_RESULT=$(cat "$ANDROID_EXIT_FILE" 2>/dev/null || echo "1")

  info "Both pipelines completed"
  echo ""

  # Display captured output
  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${PURPLE}${BOLD}  iOS Pipeline Results${NC}"
  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  cat "$IOS_OUTPUT_FILE"
  echo ""

  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${PURPLE}${BOLD}  Android Pipeline Results${NC}"
  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  cat "$ANDROID_OUTPUT_FILE"
  echo ""

  # Parse iOS results from logs
  if [ -f "$RESULTS_DIR/ios_build_$TIMESTAMP.log" ]; then
    if grep -q "BUILD SUCCEEDED" "$RESULTS_DIR/ios_build_$TIMESTAMP.log" 2>/dev/null; then
      IOS_BUILD_STATUS="pass"
    else
      IOS_BUILD_STATUS="fail"
    fi
    IOS_BUILD_DURATION=0  # Duration tracking happens in the pipeline functions
  fi

  if [ -f "$RESULTS_DIR/ios_unit_$TIMESTAMP.log" ]; then
    local test_results=$(parse_xcodebuild_test_output "$RESULTS_DIR/ios_unit_$TIMESTAMP.log")
    IOS_UNIT_COUNT=$(echo "$test_results" | cut -d':' -f1)
    IOS_UNIT_PASSED=$(echo "$test_results" | cut -d':' -f2)
    IOS_UNIT_FAILED=$(echo "$test_results" | cut -d':' -f3)
    if [ "$IOS_UNIT_FAILED" -eq 0 ] && [ "$IOS_UNIT_COUNT" -ge "$EXPECTED_IOS_UNIT_TESTS" ]; then
      IOS_UNIT_STATUS="pass"
    else
      IOS_UNIT_STATUS="fail"
    fi
    IOS_UNIT_DURATION=0
  fi

  if [ "$SKIP_UI_TESTS" = true ]; then
    IOS_UI_STATUS="skip"
    IOS_UI_COUNT=0
    IOS_UI_PASSED=0
    IOS_UI_FAILED=0
    IOS_UI_DURATION=0
  elif [ -f "$RESULTS_DIR/ios_ui_$TIMESTAMP.log" ]; then
    local test_results=$(parse_xcodebuild_test_output "$RESULTS_DIR/ios_ui_$TIMESTAMP.log")
    IOS_UI_COUNT=$(echo "$test_results" | cut -d':' -f1)
    IOS_UI_PASSED=$(echo "$test_results" | cut -d':' -f2)
    IOS_UI_FAILED=$(echo "$test_results" | cut -d':' -f3)
    if [ "$IOS_UI_FAILED" -eq 0 ] && [ "$IOS_UI_COUNT" -gt 0 ]; then
      IOS_UI_STATUS="pass"
    elif [ "$IOS_UI_COUNT" -eq 0 ]; then
      IOS_UI_STATUS="no_tests"
    else
      IOS_UI_STATUS="fail"
    fi
    IOS_UI_DURATION=0
  fi

  # Parse Android results from logs
  if [ -f "$RESULTS_DIR/android_build_$TIMESTAMP.log" ]; then
    if grep -q "BUILD SUCCESSFUL" "$RESULTS_DIR/android_build_$TIMESTAMP.log" 2>/dev/null; then
      ANDROID_BUILD_STATUS="pass"
    else
      ANDROID_BUILD_STATUS="fail"
    fi
    ANDROID_BUILD_DURATION=0
  fi

  if [ -f "$RESULTS_DIR/android_unit_$TIMESTAMP.log" ]; then
    local test_results=$(parse_gradle_test_output "$RESULTS_DIR/android_unit_$TIMESTAMP.log")
    ANDROID_UNIT_COUNT=$(echo "$test_results" | cut -d':' -f1)
    ANDROID_UNIT_PASSED=$(echo "$test_results" | cut -d':' -f2)
    ANDROID_UNIT_FAILED=$(echo "$test_results" | cut -d':' -f3)
    if [ "$ANDROID_UNIT_FAILED" -eq 0 ] && [ "$ANDROID_UNIT_COUNT" -ge "$EXPECTED_ANDROID_UNIT_TESTS" ]; then
      ANDROID_UNIT_STATUS="pass"
    else
      ANDROID_UNIT_STATUS="fail"
    fi
    ANDROID_UNIT_DURATION=0
  fi

  if [ "$SKIP_UI_TESTS" = true ]; then
    ANDROID_UI_STATUS="skip"
    ANDROID_UI_COUNT=0
    ANDROID_UI_PASSED=0
    ANDROID_UI_FAILED=0
    ANDROID_UI_DURATION=0
  elif [ -f "$RESULTS_DIR/android_ui_$TIMESTAMP.log" ]; then
    local test_results=$(parse_gradle_test_output "$RESULTS_DIR/android_ui_$TIMESTAMP.log" "ui")
    ANDROID_UI_COUNT=$(echo "$test_results" | cut -d':' -f1)
    ANDROID_UI_PASSED=$(echo "$test_results" | cut -d':' -f2)
    ANDROID_UI_FAILED=$(echo "$test_results" | cut -d':' -f3)
    if [ "$ANDROID_UI_FAILED" -eq 0 ] && [ "$ANDROID_UI_COUNT" -gt 0 ]; then
      ANDROID_UI_STATUS="pass"
    elif [ "$ANDROID_UI_COUNT" -eq 0 ]; then
      ANDROID_UI_STATUS="no_tests"
    else
      ANDROID_UI_STATUS="fail"
    fi
    ANDROID_UI_DURATION=0
  fi

  # Clean up temp files
  rm -f "$IOS_EXIT_FILE" "$ANDROID_EXIT_FILE" "$IOS_OUTPUT_FILE" "$ANDROID_OUTPUT_FILE"

  # Check results
  if [ "$IOS_RESULT" -ne 0 ] || [ "$ANDROID_RESULT" -ne 0 ]; then
    OVERALL_SUCCESS=false
  fi

else
  # ========================================================================
  # Sequential Execution Mode (default, backward compatible)
  # ========================================================================

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
