#!/usr/bin/env bash
set -euo pipefail

# Generate a summary report from the sync output.
# This script is called by the GitHub Actions workflow after sync completes.
# Usage: generate-report.sh <report-file>

REPORT_FILE="${1:-reports/sync-report.md}"

if [ ! -f "$REPORT_FILE" ]; then
    echo "ERROR: Report file not found: $REPORT_FILE"
    exit 1
fi

# Extract summary metrics for the workflow
total_repos=$(grep "Total repositories" "$REPORT_FILE" | grep -oE '[0-9]+' || echo "0")
compliant=$(grep "Compliant" "$REPORT_FILE" | grep -oE '[0-9]+' || echo "0")
drift=$(grep "Drift detected" "$REPORT_FILE" | grep -oE '[0-9]+' || echo "0")

echo "total_repos=$total_repos"
echo "compliant=$compliant"
echo "drift=$drift"

# Output for GitHub Actions
if [ "${GITHUB_OUTPUT:-}" != "" ]; then
    {
        echo "total_repos=$total_repos"
        echo "compliant=$compliant"
        echo "drift=$drift"
        echo "has_drift=$([ "$drift" -gt 0 ] && echo "true" || echo "false")"
    } >> "$GITHUB_OUTPUT"
fi
