#!/bin/bash

# iOS Test Runner Script
# Usage: ./test.sh {unit|ui|all|clean|coverage}

set -e  # Exit on error

# Ensure we are in the ios directory
cd "$(dirname "$0")/../../ios" || exit 1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT="JustSpent/JustSpent.xcodeproj"
SCHEME="JustSpent"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}  Just Spent - iOS Tests${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}✗ xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

# Check if xcpretty is available (optional but recommended)
USE_XCPRETTY=false
if command -v xcpretty &> /dev/null; then
    USE_XCPRETTY=true
fi

run_xcodebuild() {
    if [ "$USE_XCPRETTY" = true ]; then
        "$@" | xcpretty
    else
        "$@"
    fi
}

case "$1" in
  unit)
    echo -e "${YELLOW}Running unit tests...${NC}"
    run_xcodebuild xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -only-testing:JustSpentTests \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
    echo -e "${GREEN}✓ Unit tests complete!${NC}"
    ;;

  ui)
    echo -e "${YELLOW}Running UI tests...${NC}"
    run_xcodebuild xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -only-testing:JustSpentUITests \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
    echo -e "${GREEN}✓ UI tests complete!${NC}"
    ;;

  all)
    echo -e "${YELLOW}Running all tests (unit + UI)...${NC}"
    run_xcodebuild xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
    echo -e "${GREEN}✓ All tests complete!${NC}"
    ;;

  clean)
    echo -e "${YELLOW}Cleaning and running unit tests...${NC}"
    run_xcodebuild xcodebuild clean test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -only-testing:JustSpentTests \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
    echo -e "${GREEN}✓ Clean tests complete!${NC}"
    ;;

  coverage)
    echo -e "${YELLOW}Running tests with coverage report...${NC}"
    RESULT_BUNDLE="test-results.xcresult"

    # Remove old results
    rm -rf "$RESULT_BUNDLE"

    # Run tests with coverage
    run_xcodebuild xcodebuild test \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -enableCodeCoverage YES \
      -resultBundlePath "$RESULT_BUNDLE" \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO

    echo -e "${GREEN}✓ Tests with coverage complete!${NC}"

    # Show coverage summary
    if [ -d "$RESULT_BUNDLE" ]; then
      echo -e "${YELLOW}Coverage Summary:${NC}"
      xcrun xccov view --report "$RESULT_BUNDLE"
      echo ""
      echo -e "${YELLOW}Detailed coverage report available in: $RESULT_BUNDLE${NC}"
      echo -e "${YELLOW}To view: xcrun xccov view --report $RESULT_BUNDLE${NC}"
    fi
    ;;

  build)
    echo -e "${YELLOW}Building iOS app...${NC}"
    run_xcodebuild xcodebuild build \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -configuration Debug \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO
    echo -e "${GREEN}✓ Build complete!${NC}"
    ;;

  *)
    echo -e "${YELLOW}Usage: ./test.sh {unit|ui|all|clean|coverage|build}${NC}"
    echo ""
    echo "Commands:"
    echo "  unit     - Run unit tests only (JustSpentTests)"
    echo "  ui       - Run UI tests only (JustSpentUITests)"
    echo "  all      - Run both unit and UI tests"
    echo "  clean    - Clean build and run unit tests"
    echo "  coverage - Run tests with code coverage report"
    echo "  build    - Build the app without running tests"
    echo ""
    echo "Examples:"
    echo "  ./test.sh unit      # Quick test during development"
    echo "  ./test.sh ui        # Test UI components"
    echo "  ./test.sh all       # Full test suite before commit"
    echo "  ./test.sh coverage  # Generate coverage report"
    echo ""
    echo "Note: Install xcpretty for prettier output: gem install xcpretty"
    exit 1
    ;;
esac
