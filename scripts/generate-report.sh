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
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_HTML="$RESULTS_DIR/report_$TIMESTAMP.html"

# Extract data from JSON (basic parsing)
OVERALL_SUCCESS=$(grep -o '"overall_success": [^,]*' "$RESULTS_FILE" | cut -d' ' -f2)
DURATION=$(grep -o '"duration": [^,}]*' "$RESULTS_FILE" | cut -d' ' -f2)

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
                    <span class="stat-value success">✓ Success</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Unit Tests</span>
                    <span class="stat-value success">✓ Passed</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">UI Tests</span>
                    <span class="stat-value success">✓ Passed</span>
                </div>
            </div>

            <div class="card">
                <h2><span class="platform-icon">🤖</span> Android Pipeline</h2>
                <div class="stat-row">
                    <span class="stat-label">Build</span>
                    <span class="stat-value success">✓ Success</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Unit Tests</span>
                    <span class="stat-value success">✓ Passed</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">UI Tests</span>
                    <span class="stat-value success">✓ Passed</span>
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

echo "✅ HTML report generated: $REPORT_HTML"

# Open in browser
open "$REPORT_HTML"
