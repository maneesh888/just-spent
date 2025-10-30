#!/bin/bash

# ============================================================================
# Just Spent - HTML Report Generator
# ============================================================================
# Generates a beautiful HTML report from CI test results
#
# Usage:
#   ./generate-report.sh <results_json_file>
# ============================================================================

set -e

RESULTS_FILE="$1"

if [ -z "$RESULTS_FILE" ] || [ ! -f "$RESULTS_FILE" ]; then
  echo "Error: Results file not found: $RESULTS_FILE"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_DIR/.ci-results"

# Extract timestamp from JSON filename to ensure HTML and JSON match
JSON_BASENAME=$(basename "$RESULTS_FILE" .json)
TIMESTAMP="${JSON_BASENAME#report_}"
REPORT_HTML="$RESULTS_DIR/report_$TIMESTAMP.html"

# Extract data from JSON (basic parsing)
OVERALL_SUCCESS=$(grep -o '"overall_success": [^,]*' "$RESULTS_FILE" | cut -d' ' -f2)
# Get the last duration (overall duration, not individual test durations)
DURATION=$(grep -o '"duration": [^,}]*' "$RESULTS_FILE" | cut -d' ' -f2 | tail -1)

# Format duration
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

FORMATTED_DURATION=$(format_duration $DURATION)

# Determine status
if [ "$OVERALL_SUCCESS" = "true" ]; then
  STATUS_COLOR="#4CAF50"
  STATUS_TEXT="✅ All Checks Passed"
  STATUS_ICON="✅"
else
  STATUS_COLOR="#F44336"
  STATUS_TEXT="❌ Checks Failed"
  STATUS_ICON="❌"
fi

# Function to extract test result from JSON
extract_test_result() {
  local platform=$1
  local test_type=$2
  local field=$3  # status, duration, count, passed, or failed

  # Use Python for robust JSON parsing
  python3 -c "
import json, sys
try:
    with open('$RESULTS_FILE', 'r') as f:
        data = json.load(f)
    value = data.get('results', {}).get('$platform', {}).get('$test_type', {}).get('$field', '')
    print(value if value != '' else '')
except:
    print('')
" 2>/dev/null
}

# Function to get status HTML with test counts
get_status_html() {
  local status=$1
  local test_count=$2
  local passed=$3
  local failed=$4
  local is_build=$5  # Flag to indicate if this is a build (not test)

  case $status in
    pass)
      if [ "$is_build" = "true" ]; then
        # Builds don't have test counts, just show success
        echo "<span class=\"stat-value success\">✓ Passed</span>"
      elif [ "$test_count" -eq 0 ]; then
        echo "<span class=\"stat-value warning\">⚠ No Tests</span>"
      else
        echo "<span class=\"stat-value success\">✓ Passed ($test_count tests)</span>"
      fi
      ;;
    fail)
      if [ "$is_build" = "true" ]; then
        echo "<span class=\"stat-value error\">✗ Failed</span>"
      else
        echo "<span class=\"stat-value error\">✗ Failed ($passed/$test_count passed)</span>"
      fi
      ;;
    incomplete)
      echo "<span class=\"stat-value error\">⚠ Incomplete ($passed/$test_count executed)</span>"
      ;;
    no_tests)
      echo "<span class=\"stat-value warning\">⚠ No Tests Found</span>"
      ;;
    skip)
      echo "<span class=\"stat-value warning\">⊘ Skipped</span>"
      ;;
    *)
      echo "<span class=\"stat-value\">- Not Run</span>"
      ;;
  esac
}

# Extract iOS results
IOS_BUILD_STATUS=$(extract_test_result "ios" "build" "status")
IOS_UNIT_STATUS=$(extract_test_result "ios" "unit" "status")
IOS_UNIT_COUNT=$(extract_test_result "ios" "unit" "count")
IOS_UNIT_PASSED=$(extract_test_result "ios" "unit" "passed")
IOS_UNIT_FAILED=$(extract_test_result "ios" "unit" "failed")
IOS_UI_STATUS=$(extract_test_result "ios" "ui" "status")
IOS_UI_COUNT=$(extract_test_result "ios" "ui" "count")
IOS_UI_PASSED=$(extract_test_result "ios" "ui" "passed")
IOS_UI_FAILED=$(extract_test_result "ios" "ui" "failed")

# Extract Android results
ANDROID_BUILD_STATUS=$(extract_test_result "android" "build" "status")
ANDROID_UNIT_STATUS=$(extract_test_result "android" "unit" "status")
ANDROID_UNIT_COUNT=$(extract_test_result "android" "unit" "count")
ANDROID_UNIT_PASSED=$(extract_test_result "android" "unit" "passed")
ANDROID_UNIT_FAILED=$(extract_test_result "android" "unit" "failed")
ANDROID_UI_STATUS=$(extract_test_result "android" "ui" "status")
ANDROID_UI_COUNT=$(extract_test_result "android" "ui" "count")
ANDROID_UI_PASSED=$(extract_test_result "android" "ui" "passed")
ANDROID_UI_FAILED=$(extract_test_result "android" "ui" "failed")

# Generate iOS status HTML
IOS_BUILD_HTML=$(get_status_html "$IOS_BUILD_STATUS" "0" "0" "0" "true")
IOS_UNIT_HTML=$(get_status_html "$IOS_UNIT_STATUS" "$IOS_UNIT_COUNT" "$IOS_UNIT_PASSED" "$IOS_UNIT_FAILED" "false")
IOS_UI_HTML=$(get_status_html "$IOS_UI_STATUS" "$IOS_UI_COUNT" "$IOS_UI_PASSED" "$IOS_UI_FAILED" "false")

# Generate Android status HTML
ANDROID_BUILD_HTML=$(get_status_html "$ANDROID_BUILD_STATUS" "0" "0" "0" "true")
ANDROID_UNIT_HTML=$(get_status_html "$ANDROID_UNIT_STATUS" "$ANDROID_UNIT_COUNT" "$ANDROID_UNIT_PASSED" "$ANDROID_UNIT_FAILED" "false")
ANDROID_UI_HTML=$(get_status_html "$ANDROID_UI_STATUS" "$ANDROID_UI_COUNT" "$ANDROID_UI_PASSED" "$ANDROID_UI_FAILED" "false")

# Generate HTML
cat > "$REPORT_HTML" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Just Spent - CI Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        .header {
            background: white;
            border-radius: 16px;
            padding: 40px;
            margin-bottom: 24px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        }

        .header h1 {
            font-size: 32px;
            color: #1a202c;
            margin-bottom: 8px;
        }

        .header .subtitle {
            font-size: 16px;
            color: #718096;
        }

        .status-card {
            background: STATUS_COLOR_PLACEHOLDER;
            border-radius: 16px;
            padding: 40px;
            margin-bottom: 24px;
            color: white;
            text-align: center;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        }

        .status-card .icon {
            font-size: 64px;
            margin-bottom: 16px;
        }

        .status-card .text {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 8px;
        }

        .status-card .duration {
            font-size: 18px;
            opacity: 0.9;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 24px;
            margin-bottom: 24px;
        }

        .card {
            background: white;
            border-radius: 16px;
            padding: 32px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        }

        .card h2 {
            font-size: 20px;
            color: #1a202c;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .card .platform-icon {
            font-size: 24px;
        }

        .stat-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid #e2e8f0;
        }

        .stat-row:last-child {
            border-bottom: none;
        }

        .stat-label {
            color: #718096;
            font-size: 14px;
        }

        .stat-value {
            font-weight: 600;
            color: #1a202c;
            font-size: 16px;
        }

        .stat-value.success {
            color: #4CAF50;
        }

        .stat-value.error {
            color: #F44336;
        }

        .stat-value.warning {
            color: #FF9800;
        }

        .logs-section {
            background: white;
            border-radius: 16px;
            padding: 32px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        }

        .logs-section h2 {
            font-size: 20px;
            color: #1a202c;
            margin-bottom: 16px;
        }

        .log-item {
            background: #f7fafc;
            border-left: 4px solid #667eea;
            padding: 12px 16px;
            margin-bottom: 12px;
            border-radius: 4px;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 13px;
            color: #2d3748;
        }

        .footer {
            text-align: center;
            color: white;
            margin-top: 40px;
            font-size: 14px;
            opacity: 0.8;
        }

        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }

        .badge.success {
            background: #d4edda;
            color: #155724;
        }

        .badge.error {
            background: #f8d7da;
            color: #721c24;
        }

        .badge.skipped {
            background: #fff3cd;
            color: #856404;
        }

        @media (max-width: 768px) {
            .header {
                padding: 24px;
            }

            .header h1 {
                font-size: 24px;
            }

            .status-card {
                padding: 24px;
            }

            .status-card .icon {
                font-size: 48px;
            }

            .status-card .text {
                font-size: 24px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Just Spent - CI Report</h1>
            <p class="subtitle">Local CI Pipeline Results • TIMESTAMP_PLACEHOLDER</p>
        </div>

        <div class="status-card">
            <div class="icon">STATUS_ICON_PLACEHOLDER</div>
            <div class="text">STATUS_TEXT_PLACEHOLDER</div>
            <div class="duration">Completed in DURATION_PLACEHOLDER</div>
        </div>

        <div class="grid">
            <div class="card">
                <h2><span class="platform-icon">📱</span> iOS Pipeline</h2>
                <div class="stat-row">
                    <span class="stat-label">Build</span>
                    IOS_BUILD_PLACEHOLDER
                </div>
                <div class="stat-row">
                    <span class="stat-label">Unit Tests</span>
                    IOS_UNIT_PLACEHOLDER
                </div>
                <div class="stat-row">
                    <span class="stat-label">UI Tests</span>
                    IOS_UI_PLACEHOLDER
                </div>
            </div>

            <div class="card">
                <h2><span class="platform-icon">🤖</span> Android Pipeline</h2>
                <div class="stat-row">
                    <span class="stat-label">Build</span>
                    ANDROID_BUILD_PLACEHOLDER
                </div>
                <div class="stat-row">
                    <span class="stat-label">Unit Tests</span>
                    ANDROID_UNIT_PLACEHOLDER
                </div>
                <div class="stat-row">
                    <span class="stat-label">UI Tests</span>
                    ANDROID_UI_PLACEHOLDER
                </div>
            </div>
        </div>

        <div class="logs-section">
            <h2>📋 Test Logs</h2>
            <p class="stat-label" style="margin-bottom: 16px;">Detailed logs are available in the .ci-results directory</p>
            <div class="log-item">
                📁 Build logs: .ci-results/ios_build_*.log
            </div>
            <div class="log-item">
                📁 Unit test logs: .ci-results/*_unit_*.log
            </div>
            <div class="log-item">
                📁 UI test logs: .ci-results/*_ui_*.log
            </div>
            <div class="log-item">
                📁 Test results: .ci-results/*.xcresult
            </div>
        </div>

        <div class="footer">
            <p>Generated by Just Spent Local CI</p>
            <p>Part of the Hybrid CI/CD Approach</p>
        </div>
    </div>
</body>
</html>
EOF

# Replace placeholders
sed -i '' "s/STATUS_COLOR_PLACEHOLDER/$STATUS_COLOR/g" "$REPORT_HTML"
sed -i '' "s/STATUS_ICON_PLACEHOLDER/$STATUS_ICON/g" "$REPORT_HTML"
sed -i '' "s/STATUS_TEXT_PLACEHOLDER/$STATUS_TEXT/g" "$REPORT_HTML"
sed -i '' "s/DURATION_PLACEHOLDER/$FORMATTED_DURATION/g" "$REPORT_HTML"
sed -i '' "s/TIMESTAMP_PLACEHOLDER/$(date '+%Y-%m-%d %H:%M:%S')/g" "$REPORT_HTML"

# Replace iOS test result placeholders (using @ as delimiter to avoid conflicts with HTML)
sed -i '' "s@IOS_BUILD_PLACEHOLDER@$IOS_BUILD_HTML@g" "$REPORT_HTML"
sed -i '' "s@IOS_UNIT_PLACEHOLDER@$IOS_UNIT_HTML@g" "$REPORT_HTML"
sed -i '' "s@IOS_UI_PLACEHOLDER@$IOS_UI_HTML@g" "$REPORT_HTML"

# Replace Android test result placeholders
sed -i '' "s@ANDROID_BUILD_PLACEHOLDER@$ANDROID_BUILD_HTML@g" "$REPORT_HTML"
sed -i '' "s@ANDROID_UNIT_PLACEHOLDER@$ANDROID_UNIT_HTML@g" "$REPORT_HTML"
sed -i '' "s@ANDROID_UI_PLACEHOLDER@$ANDROID_UI_HTML@g" "$REPORT_HTML"

echo "✅ HTML report generated: $REPORT_HTML"

# Open in browser
open "$REPORT_HTML"
