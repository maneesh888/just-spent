#!/bin/bash

# ============================================================================
# Just Spent - Parallel CI/CD Script
# ============================================================================
# Runs iOS and Android CI checks in parallel for faster feedback.
# Since they have no dependencies, both can run simultaneously.
#
# Usage:
#   ./local-ci-parallel.sh [--quick] [--skip-ui] [--kill-emulator]
#
# Options:
#   --quick          Fast mode: build + unit tests only
#   --skip-ui        Skip UI tests (faster, unit tests only)
#   --kill-emulator  Stop Android emulator after tests complete
#   --help           Show this help message
#
# Performance:
#   Sequential (--all): ~10-15 min total
#   Parallel:           ~6-8 min total (40-50% faster)
# ============================================================================

set -o pipefail  # Catch errors in pipes

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

# Parse arguments
EXTRA_ARGS=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      grep "^#" "$0" | grep -v "#!/bin/bash" | sed 's/^# //'
      exit 0
      ;;
    *)
      EXTRA_ARGS="$EXTRA_ARGS $1"
      shift
      ;;
  esac
done

# ============================================================================
# Setup
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Log files
IOS_LOG="/tmp/parallel_ios_$TIMESTAMP.log"
ANDROID_LOG="/tmp/parallel_android_$TIMESTAMP.log"

# Create results directory
mkdir -p "$SCRIPT_DIR/.ci-results"

echo -e "${BOLD}🚀 Just Spent - Parallel CI Pipeline${NC}"
echo "========================================"
echo ""

# ============================================================================
# Run Tests in Parallel
# ============================================================================
echo -e "${ICON_INFO}Starting iOS and Android tests in ${BOLD}parallel${NC}..."
echo ""

# Start timestamp
START_TIME=$(date +%s)

# Run iOS in background
echo -e "${BLUE}${ICON_RUNNING} iOS:${NC} Running in background..."
"$SCRIPT_DIR/local-ci.sh" --ios $EXTRA_ARGS > "$IOS_LOG" 2>&1 &
IOS_PID=$!

# Run Android in background
echo -e "${GREEN}${ICON_RUNNING} Android:${NC} Running in background..."
"$SCRIPT_DIR/local-ci.sh" --android $EXTRA_ARGS > "$ANDROID_LOG" 2>&1 &
ANDROID_PID=$!

echo ""
echo "📊 Monitor progress:"
echo "   iOS log:     tail -f $IOS_LOG"
echo "   Android log: tail -f $ANDROID_LOG"
echo ""

# ============================================================================
# Wait for Completion
# ============================================================================
echo -e "${ICON_INFO}Waiting for both platforms to complete..."
echo ""

# Wait for both processes
IOS_EXIT_CODE=0
ANDROID_EXIT_CODE=0

wait $IOS_PID
IOS_EXIT_CODE=$?

wait $ANDROID_PID
ANDROID_EXIT_CODE=$?

# Calculate duration
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_DURATION / 60))
SECONDS=$((TOTAL_DURATION % 60))

# ============================================================================
# Display Results
# ============================================================================
echo ""
echo "========================================"
echo -e "${BOLD}Test Results${NC}"
echo "========================================"
echo ""

# iOS Results
if [ $IOS_EXIT_CODE -eq 0 ]; then
  echo -e "${BLUE}${ICON_SUCCESS} iOS:${NC} All checks passed"
else
  echo -e "${BLUE}${ICON_ERROR} iOS:${NC} Some checks failed (exit code: $IOS_EXIT_CODE)"
  echo -e "   ${CYAN}See log:${NC} $IOS_LOG"
fi

# Android Results
if [ $ANDROID_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}${ICON_SUCCESS} Android:${NC} All checks passed"
else
  echo -e "${GREEN}${ICON_ERROR} Android:${NC} Some checks failed (exit code: $ANDROID_EXIT_CODE)"
  echo -e "   ${CYAN}See log:${NC} $ANDROID_LOG"
fi

echo ""
echo "========================================"

# Overall Result
if [ $IOS_EXIT_CODE -eq 0 ] && [ $ANDROID_EXIT_CODE -eq 0 ]; then
  echo -e "${ICON_SUCCESS} ${GREEN}${BOLD}All CI checks passed!${NC}"
  echo ""
  echo -e "Total duration: ${BOLD}${MINUTES}m ${SECONDS}s${NC}"
  echo ""

  # Cleanup logs on success (optional)
  # rm -f "$IOS_LOG" "$ANDROID_LOG"

  exit 0
else
  echo -e "${ICON_ERROR} ${RED}${BOLD}CI checks failed!${NC}"
  echo ""
  echo -e "Total duration: ${BOLD}${MINUTES}m ${SECONDS}s${NC}"
  echo ""
  echo "📋 Review failure logs:"
  if [ $IOS_EXIT_CODE -ne 0 ]; then
    echo -e "   iOS: ${CYAN}$IOS_LOG${NC}"
  fi
  if [ $ANDROID_EXIT_CODE -ne 0 ]; then
    echo -e "   Android: ${CYAN}$ANDROID_LOG${NC}"
  fi
  echo ""

  exit 1
fi
