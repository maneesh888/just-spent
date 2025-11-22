#!/bin/bash
# Verify Apple ID credentials for App Store Connect
# Usage: ./scripts/verify-apple-credentials.sh "apple_id" "app_specific_password"

set -e

APPLE_ID="$1"
APP_SPECIFIC_PASSWORD="$2"

if [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo "Usage: ./scripts/verify-apple-credentials.sh \"apple_id\" \"app_specific_password\""
    echo "Example: ./scripts/verify-apple-credentials.sh \"user@email.com\" \"xxxx-xxxx-xxxx-xxxx\""
    exit 1
fi

echo "🔐 Verifying Apple ID credentials..."
echo "   Apple ID: $APPLE_ID"
echo "   Password: ****-****-****-****"
echo ""

# Use fastlane's spaceship to verify credentials
cd ios

export FASTLANE_USER="$APPLE_ID"
export FASTLANE_PASSWORD="$APP_SPECIFIC_PASSWORD"
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="$APP_SPECIFIC_PASSWORD"

# Try to authenticate using fastlane
bundle exec ruby -e "
require 'spaceship'
begin
  Spaceship::ConnectAPI.login('$APPLE_ID', '$APP_SPECIFIC_PASSWORD')
  puts '✅ Authentication successful!'
  puts '   Your Apple ID credentials are valid.'
rescue => e
  puts '❌ Authentication failed!'
  puts \"   Error: #{e.message}\"
  exit 1
end
"
