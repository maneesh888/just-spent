#!/bin/bash

# ============================================================================
# Just Spent - Local CI/CD Script
# ============================================================================
# This script runs the same checks as GitHub Actions but locally for faster
# feedback during development. Part of the hybrid CI/CD approach.
#
# Usage:
#   ./local-ci.sh [--ios] [--android] [--all] [--skip-ui] [--quick]
#
# Options:
#   --ios        Run iOS checks only
#   --android    Run Android checks only
#   --all        Run both iOS and Android (default)
#   --skip-ui    Skip UI tests (faster, unit tests only)
#   --quick      Fast mode: build + unit tests only
#   --help       Show this help message
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

# ============================================================================
# Parse Command Line Arguments
# ============================================================================
RUN_IOS=false
RUN_ANDROID=false
RUN_ALL=false
SKIP_UI_TESTS=false
QUICK_MODE=false

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

# Initialize results directory
init_results() {
  mkdir -p "$RESULTS_DIR"
  echo "{" > "$REPORT_FILE"
  echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," >> "$REPORT_FILE"
  echo "  \"results\": {" >> "$REPORT_FILE"
}

# Finalize results file
finalize_results() {
  local success=$1
  echo "  }," >> "$REPORT_FILE"
  echo "  \"overall_success\": $success," >> "$REPORT_FILE"
  echo "  \"duration\": $TOTAL_DURATION" >> "$REPORT_FILE"
  echo "}" >> "$REPORT_FILE"
}

# ============================================================================
# iOS Pipeline Functions
# ============================================================================

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
  else
    local build_time=$(end_timer)
    error "iOS build failed ($(format_duration $build_time))"
    error "Check log: $RESULTS_DIR/ios_build_$TIMESTAMP.log"
    ios_success=false
    cd "$SCRIPT_DIR"
    return 1
  fi

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
    success "iOS unit tests passed ($(format_duration $test_time))"
  else
    local test_time=$(end_timer)
    error "iOS unit tests failed ($(format_duration $test_time))"
    error "Check log: $RESULTS_DIR/ios_unit_$TIMESTAMP.log"
    ios_success=false
  fi

  # iOS UI Tests
  if [ "$SKIP_UI_TESTS" = false ]; then
    running "Running iOS UI tests..."
    start_timer
    if xcodebuild test \
      -project JustSpent.xcodeproj \
      -scheme JustSpent \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -only-testing:JustSpentUITests \
      -enableCodeCoverage YES \
      -resultBundlePath "$RESULTS_DIR/ios_ui_$TIMESTAMP.xcresult" \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO \
      > "$RESULTS_DIR/ios_ui_$TIMESTAMP.log" 2>&1; then

      local test_time=$(end_timer)
      success "iOS UI tests passed ($(format_duration $test_time))"
    else
      local test_time=$(end_timer)
      error "iOS UI tests failed ($(format_duration $test_time))"
      error "Check log: $RESULTS_DIR/ios_ui_$TIMESTAMP.log"
      ios_success=false
    fi
  else
    skip "iOS UI tests skipped (--skip-ui flag)"
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
  else
    local build_time=$(end_timer)
    error "Android build failed ($(format_duration $build_time))"
    error "Check log: $RESULTS_DIR/android_build_$TIMESTAMP.log"
    android_success=false
    cd "$SCRIPT_DIR"
    return 1
  fi

  # Android Unit Tests
  running "Running Android unit tests..."
  start_timer
  if ./gradlew testDebugUnitTest --stacktrace \
    > "$RESULTS_DIR/android_unit_$TIMESTAMP.log" 2>&1; then

    local test_time=$(end_timer)
    success "Android unit tests passed ($(format_duration $test_time))"
  else
    local test_time=$(end_timer)
    error "Android unit tests failed ($(format_duration $test_time))"
    error "Check log: $RESULTS_DIR/android_unit_$TIMESTAMP.log"
    android_success=false
  fi

  # Android UI Tests (only if emulator is running)
  if [ "$SKIP_UI_TESTS" = false ]; then
    if adb devices | grep -q "device$"; then
      running "Running Android UI tests..."
      start_timer
      if ./gradlew connectedDebugAndroidTest --stacktrace \
        > "$RESULTS_DIR/android_ui_$TIMESTAMP.log" 2>&1; then

        local test_time=$(end_timer)
        success "Android UI tests passed ($(format_duration $test_time))"
      else
        local test_time=$(end_timer)
        error "Android UI tests failed ($(format_duration $test_time))"
        error "Check log: $RESULTS_DIR/android_ui_$TIMESTAMP.log"
        android_success=false
      fi
    else
      warning "Android UI tests skipped (no emulator/device detected)"
      info "Start an emulator to run UI tests"
    fi
  else
    skip "Android UI tests skipped (--skip-ui flag)"
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
