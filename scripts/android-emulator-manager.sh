#!/bin/bash

# ============================================================================
# Android Emulator Manager for Local CI
# ============================================================================
# Manages Android emulator lifecycle for local CI testing:
# - Detects running emulators
# - Launches emulator if needed
# - Grants necessary permissions
# - Provides cleanup capabilities
#
# Usage:
#   ./android-emulator-manager.sh start [--wait] [--grant-permissions]
#   ./android-emulator-manager.sh stop
#   ./android-emulator-manager.sh status
#   ./android-emulator-manager.sh grant-permissions
# ============================================================================

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# ============================================================================
# Configuration
# ============================================================================

# Emulator boot timeout (seconds)
BOOT_TIMEOUT=300  # 5 minutes

# Package name for Just Spent app
PACKAGE_NAME="com.justspent.app"

# Required permissions
REQUIRED_PERMISSIONS=(
  "android.permission.RECORD_AUDIO"
  "android.permission.MODIFY_AUDIO_SETTINGS"
)

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Icons
ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_INFO="ℹ️ "
ICON_RUNNING="⏳"
ICON_WARNING="⚠️ "

# ============================================================================
# Helper Functions
# ============================================================================

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
  echo -e "${YELLOW}${ICON_WARNING}$1${NC}"
}

running() {
  echo -e "${BLUE}${ICON_RUNNING} $1${NC}"
}

# ============================================================================
# Emulator Detection Functions
# ============================================================================

# Check if any emulator is currently running
is_emulator_running() {
  adb devices 2>/dev/null | grep -q "emulator.*device$"
}

# Get running emulator serial
get_running_emulator() {
  adb devices 2>/dev/null | grep "emulator.*device$" | awk '{print $1}' | head -n 1
}

# Check if emulator is fully booted
is_emulator_booted() {
  local serial=$1
  local boot_completed=$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  [ "$boot_completed" = "1" ]
}

# ============================================================================
# AVD Management Functions
# ============================================================================

# List all available AVDs
list_avds() {
  emulator -list-avds 2>/dev/null
}

# Select best available AVD
# Preference: API 28+, Google APIs, then first available
select_best_avd() {
  local avds=$(list_avds)

  if [ -z "$avds" ]; then
    return 1
  fi

  # For now, just return the first available AVD
  # In future, could parse AVD configs to check API level and features
  echo "$avds" | head -n 1
}

# ============================================================================
# Emulator Launch Functions
# ============================================================================

# Launch emulator in background
launch_emulator() {
  local avd_name=$1

  info "Launching Android emulator: $avd_name"

  # Launch emulator in background
  # -no-snapshot-load: Start fresh
  # -no-boot-anim: Skip boot animation for faster startup
  # -no-audio: Disable audio (not needed for tests)
  # -gpu auto: Automatic GPU acceleration
  nohup emulator -avd "$avd_name" \
    -no-snapshot-load \
    -no-boot-anim \
    -no-audio \
    -gpu auto \
    > /dev/null 2>&1 &

  local emulator_pid=$!
  echo "$emulator_pid" > /tmp/justspent_emulator.pid

  sleep 5  # Give emulator time to start

  # Check if process is still running
  if ! ps -p $emulator_pid > /dev/null 2>&1; then
    error "Emulator process died immediately after launch"
    return 1
  fi

  success "Emulator process started (PID: $emulator_pid)"
  return 0
}

# Wait for emulator to fully boot
wait_for_emulator_boot() {
  local timeout=$1
  local serial=$2

  running "Waiting for emulator to boot (timeout: ${timeout}s)..."

  local elapsed=0
  local interval=5

  while [ $elapsed -lt $timeout ]; do
    if is_emulator_booted "$serial"; then
      success "Emulator booted successfully (${elapsed}s)"
      return 0
    fi

    echo -n "."
    sleep $interval
    elapsed=$((elapsed + interval))
  done

  echo ""
  error "Emulator boot timeout after ${timeout}s"
  return 1
}

# ============================================================================
# Permission Management Functions
# ============================================================================

# Grant a single permission
grant_permission() {
  local serial=$1
  local permission=$2

  adb -s "$serial" shell pm grant "$PACKAGE_NAME" "$permission" 2>/dev/null
  return $?
}

# Grant all required permissions
grant_all_permissions() {
  local serial=$1

  info "Granting required permissions to $PACKAGE_NAME..."

  for permission in "${REQUIRED_PERMISSIONS[@]}"; do
    if grant_permission "$serial" "$permission"; then
      success "Granted: $permission"
    else
      warning "Failed to grant: $permission (may not be needed or already granted)"
    fi
  done
}

# Verify a single permission is granted
verify_permission() {
  local serial=$1
  local permission=$2

  adb -s "$serial" shell dumpsys package "$PACKAGE_NAME" 2>/dev/null | \
    grep -q "$permission.*granted=true"
}

# Verify all required permissions
verify_all_permissions() {
  local serial=$1

  info "Verifying granted permissions..."

  local all_granted=true
  for permission in "${REQUIRED_PERMISSIONS[@]}"; do
    if verify_permission "$serial" "$permission"; then
      success "Verified: $permission"
    else
      warning "Not granted: $permission"
      all_granted=false
    fi
  done

  if [ "$all_granted" = true ]; then
    success "All required permissions granted and verified"
    return 0
  else
    warning "Some permissions may not be granted"
    return 1
  fi
}

# ============================================================================
# Emulator Stop Functions
# ============================================================================

# Kill running emulator
stop_emulator() {
  local serial=$1

  if [ -z "$serial" ]; then
    serial=$(get_running_emulator)
  fi

  if [ -z "$serial" ]; then
    info "No emulator running to stop"
    return 0
  fi

  info "Stopping emulator: $serial"
  adb -s "$serial" emu kill 2>/dev/null || true

  # Also kill by PID if we saved it
  if [ -f /tmp/justspent_emulator.pid ]; then
    local pid=$(cat /tmp/justspent_emulator.pid)
    if ps -p $pid > /dev/null 2>&1; then
      kill $pid 2>/dev/null || true
    fi
    rm -f /tmp/justspent_emulator.pid
  fi

  sleep 2
  success "Emulator stopped"
}

# ============================================================================
# Main Commands
# ============================================================================

cmd_status() {
  echo ""
  info "Checking emulator status..."
  echo ""

  if is_emulator_running; then
    local serial=$(get_running_emulator)
    success "Emulator is running: $serial"

    if is_emulator_booted "$serial"; then
      success "Emulator is fully booted"
    else
      warning "Emulator is still booting..."
    fi
    return 0
  else
    info "No emulator is currently running"

    echo ""
    info "Available AVDs:"
    local avds=$(list_avds)
    if [ -n "$avds" ]; then
      echo "$avds" | while read -r avd; do
        echo "  - $avd"
      done
    else
      warning "No AVDs found. Create one using Android Studio AVD Manager."
    fi
    return 1
  fi
}

cmd_start() {
  local wait_for_boot=false
  local grant_perms=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --wait)
        wait_for_boot=true
        shift
        ;;
      --grant-permissions)
        grant_perms=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  echo ""
  info "Starting Android emulator..."
  echo ""

  # Check if emulator is already running
  if is_emulator_running; then
    local serial=$(get_running_emulator)
    success "Emulator already running: $serial"

    if is_emulator_booted "$serial"; then
      success "Emulator is fully booted"

      if [ "$grant_perms" = true ]; then
        echo ""
        grant_all_permissions "$serial"
        verify_all_permissions "$serial"
      fi

      return 0
    else
      warning "Emulator is still booting..."
      if [ "$wait_for_boot" = true ]; then
        wait_for_emulator_boot $BOOT_TIMEOUT "$serial"
      fi
      return 0
    fi
  fi

  # Select best AVD
  local avd_name=$(select_best_avd)

  if [ -z "$avd_name" ]; then
    error "No AVDs available"
    echo ""
    warning "Create an AVD using Android Studio:"
    echo "  1. Open Android Studio"
    echo "  2. Tools → Device Manager"
    echo "  3. Create Device"
    echo "  4. Recommended: Pixel 6, API 28+, Google APIs"
    return 1
  fi

  info "Selected AVD: $avd_name"
  echo ""

  # Launch emulator
  if ! launch_emulator "$avd_name"; then
    error "Failed to launch emulator"
    return 1
  fi

  # Wait for ADB to detect device
  running "Waiting for ADB to detect emulator..."
  local max_wait=30
  local waited=0
  while ! is_emulator_running && [ $waited -lt $max_wait ]; do
    sleep 2
    waited=$((waited + 2))
  done

  if ! is_emulator_running; then
    error "Emulator not detected by ADB after ${max_wait}s"
    return 1
  fi

  local serial=$(get_running_emulator)
  success "Emulator detected: $serial"
  echo ""

  # Wait for boot if requested
  if [ "$wait_for_boot" = true ]; then
    if ! wait_for_emulator_boot $BOOT_TIMEOUT "$serial"; then
      error "Emulator failed to boot"
      return 1
    fi

    # Unlock screen
    info "Unlocking screen..."
    adb -s "$serial" shell input keyevent 82 2>/dev/null || true
    sleep 1
  fi

  # Grant permissions if requested
  if [ "$grant_perms" = true ]; then
    echo ""
    grant_all_permissions "$serial"
    verify_all_permissions "$serial" || true
  fi

  echo ""
  success "Emulator is ready!"
  return 0
}

cmd_stop() {
  echo ""
  info "Stopping Android emulator..."
  echo ""

  stop_emulator

  echo ""
  success "Done!"
  return 0
}

cmd_grant_permissions() {
  echo ""
  info "Granting permissions..."
  echo ""

  if ! is_emulator_running; then
    error "No emulator is running"
    info "Start an emulator first: $0 start"
    return 1
  fi

  local serial=$(get_running_emulator)

  if ! is_emulator_booted "$serial"; then
    warning "Emulator is still booting. Waiting..."
    wait_for_emulator_boot $BOOT_TIMEOUT "$serial"
  fi

  grant_all_permissions "$serial"
  verify_all_permissions "$serial"

  echo ""
  success "Done!"
  return 0
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
  local command=${1:-status}
  shift || true

  case "$command" in
    start)
      cmd_start "$@"
      ;;
    stop)
      cmd_stop "$@"
      ;;
    status)
      cmd_status "$@"
      ;;
    grant-permissions)
      cmd_grant_permissions "$@"
      ;;
    *)
      echo "Android Emulator Manager for Just Spent"
      echo ""
      echo "Usage: $0 <command> [options]"
      echo ""
      echo "Commands:"
      echo "  start              Launch emulator if not running"
      echo "    --wait           Wait for emulator to fully boot"
      echo "    --grant-permissions  Grant app permissions after boot"
      echo ""
      echo "  stop               Stop running emulator"
      echo "  status             Check emulator status"
      echo "  grant-permissions  Grant app permissions to running emulator"
      echo ""
      echo "Examples:"
      echo "  $0 status"
      echo "  $0 start --wait --grant-permissions"
      echo "  $0 grant-permissions"
      echo "  $0 stop"
      exit 1
      ;;
  esac
}

# Run main function
main "$@"
