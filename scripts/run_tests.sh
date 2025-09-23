#!/bin/bash

# Énekeskönyv App Test Runner
# This script runs all tests for the app

set -e

echo "🧪 Running Énekeskönyv App Tests"
echo "================================="

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Run static analysis
echo "🔍 Running static analysis..."
flutter analyze --no-fatal-warnings

# Run unit tests
echo "🧪 Running unit tests..."
flutter test test/unit/ --coverage

# Run widget tests
echo "🎨 Running widget tests..."
flutter test test/widget/ --coverage

# Run all tests (including integration)
echo "🚀 Running all tests..."
flutter test --coverage

# Run integration tests (if available)
if [ -d "integration_test" ]; then
    echo "🔄 Running integration tests..."
    flutter test integration_test/ --coverage
fi

# Generate coverage report
echo "📊 Generating coverage report..."
genhtml coverage/lcov.info -o coverage/html

echo "✅ All tests completed successfully!"
echo "📋 Coverage report available at: coverage/html/index.html"