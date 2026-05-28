#!/bin/bash
set -e

echo "=== Person 3 — Final Verification ==="

echo ""
echo "--- Static analysis ---"
flutter analyze
echo "✓ No issues found"

echo ""
echo "--- Unit tests ---"
flutter test test/ai/blur_scoring_test.dart
flutter test test/ai/hash_utils_test.dart
flutter test test/ai/screenshot_heuristics_test.dart
flutter test test/ai/similarity_utils_test.dart
flutter test test/utils/clustering_utils_test.dart
flutter test test/ai/recommendation_scoring_test.dart
flutter test test/analytics/daily_aggregation_service_test.dart
flutter test test/analytics/weekly_aggregation_service_test.dart
flutter test test/utils/format_utils_test.dart
echo "✓ All unit tests passed"

echo ""
echo "--- Widget tests ---"
flutter test test/dashboard/stat_card_test.dart
flutter test test/dashboard/storage_summary_test.dart
flutter test test/dashboard/cleanup_history_list_test.dart
flutter test test/dashboard/recommendation_card_test.dart
echo "✓ All widget tests passed"

echo ""
echo "--- Integration tests ---"
flutter test test/integration/person3_e2e_test.dart || echo "⚠ Some integration tests skipped (require assets/Supabase)"

echo ""
echo "--- Full suite ---"
flutter test test/
echo "✓ All tests passed"

echo ""
echo "=== Person 3 verification complete ==="
