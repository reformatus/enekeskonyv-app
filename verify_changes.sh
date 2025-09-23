#!/bin/bash
cd /home/runner/work/enekeskonyv-app/enekeskonyv-app

echo "=== Checking Dart analysis ==="
# Check for analysis without flutter command since it's not available
dart analyze lib/ || echo "Analysis errors found but continuing..."

echo "=== File structure check ==="
echo "Checking if all new files exist:"
ls -la lib/error_dialog.dart || echo "error_dialog.dart not found"
ls -la lib/error_handler.dart || echo "error_handler.dart not found"

echo "=== Import check ==="
echo "Checking imports in main files:"
grep -n "import.*error" lib/main.dart || echo "No error imports in main.dart"
grep -n "import.*error" lib/settings_provider.dart || echo "No error imports in settings_provider.dart"
grep -n "import.*error" lib/home/home_page.dart || echo "No error imports in home_page.dart"

echo "=== Verification complete ==="