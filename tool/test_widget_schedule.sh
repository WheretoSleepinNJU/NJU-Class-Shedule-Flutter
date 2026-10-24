#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
qa_test_dir=$(mktemp -d)
trap 'rm -rf "$qa_test_dir"' EXIT
xcrun swiftc ios/Runner/WidgetDataModels.swift ios/WidgetLogicTests/main.swift -o "$qa_test_dir/widget-schedule-tests"
"$qa_test_dir/widget-schedule-tests"
