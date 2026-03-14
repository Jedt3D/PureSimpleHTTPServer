#!/bin/bash
# run_tests.sh — run all PureUnit tests for PureSimpleHTTPServer
# Usage: ./run_tests.sh [--report]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPORT_FLAG=""
if [ "$1" = "--report" ]; then
  REPORT_FLAG="-r $PROJECT_DIR/docs/test_report.html"
  echo "Report will be written to docs/test_report.html"
fi

echo "=== PureSimpleHTTPServer Test Suite ==="
echo "Running tests in: $SCRIPT_DIR"
echo ""

pureunit -i -v $REPORT_FLAG "$SCRIPT_DIR"/test_*.pb

echo ""
echo "=== All tests passed ==="
