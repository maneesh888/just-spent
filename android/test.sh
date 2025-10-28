#!/bin/bash

# Android Test Runner Script
# Usage: ./test.sh {unit|ui|all|watch|clean}

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}  Just Spent - Android Tests${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

case "$1" in
  unit)
    echo -e "${YELLOW}Running unit tests...${NC}"
    ./gradlew testDebugUnitTest --info
    echo -e "${GREEN}✓ Unit tests complete!${NC}"
    echo -e "${YELLOW}Report: android/app/build/reports/tests/testDebugUnitTest/index.html${NC}"
    ;;

  ui)
    echo -e "${YELLOW}Running UI tests (requires emulator or device)...${NC}"
    # Check if any device is connected
    if ! adb devices | grep -q "device$"; then
      echo -e "${RED}✗ No device/emulator detected. Please connect a device or start an emulator.${NC}"
      exit 1
    fi
    ./gradlew connectedDebugAndroidTest --info
    echo -e "${GREEN}✓ UI tests complete!${NC}"
    echo -e "${YELLOW}Report: android/app/build/reports/androidTests/connected/index.html${NC}"
    ;;

  all)
    echo -e "${YELLOW}Running all tests (unit + UI)...${NC}"
    ./gradlew testDebugUnitTest connectedDebugAndroidTest
    echo -e "${GREEN}✓ All tests complete!${NC}"
    ;;

  watch)
    echo -e "${YELLOW}Running tests in watch mode...${NC}"
    echo -e "${YELLOW}Tests will re-run on code changes${NC}"
    ./gradlew testDebugUnitTest --continuous
    ;;

  clean)
    echo -e "${YELLOW}Cleaning and running all tests...${NC}"
    ./gradlew clean testDebugUnitTest
    echo -e "${GREEN}✓ Clean tests complete!${NC}"
    ;;

  coverage)
    echo -e "${YELLOW}Running tests with coverage report...${NC}"
    ./gradlew testDebugUnitTest jacocoTestReport
    echo -e "${GREEN}✓ Tests with coverage complete!${NC}"
    echo -e "${YELLOW}Coverage report: android/app/build/reports/jacoco/test/html/index.html${NC}"
    ;;

  *)
    echo -e "${YELLOW}Usage: ./test.sh {unit|ui|all|watch|clean|coverage}${NC}"
    echo ""
    echo "Commands:"
    echo "  unit     - Run unit tests only (fast, no device needed)"
    echo "  ui       - Run UI tests on connected device/emulator"
    echo "  all      - Run both unit and UI tests"
    echo "  watch    - Run tests continuously on file changes"
    echo "  clean    - Clean build and run unit tests"
    echo "  coverage - Run tests with code coverage report"
    echo ""
    echo "Examples:"
    echo "  ./test.sh unit      # Quick test during development"
    echo "  ./test.sh ui        # Test UI components"
    echo "  ./test.sh all       # Full test suite before commit"
    exit 1
    ;;
esac
