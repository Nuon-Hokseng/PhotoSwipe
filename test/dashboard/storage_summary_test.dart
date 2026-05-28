import 'package:background_remover/features/dashboard/widgets/storage_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  group('StorageSummary', () {
    testWidgets('formats storage bytes correctly', (tester) async {
      await tester.pumpWidget(_wrap(const StorageSummary(
        storageSavedBytes: 1048576, // 1.0 MB
        totalPhotosDeleted: 5,
        totalPhotosReviewed: 10,
      )));
      expect(find.textContaining('1.0 MB'), findsOneWidget);
    });

    testWidgets('shows 0% progress when totalPhotosReviewed is 0', (tester) async {
      await tester.pumpWidget(_wrap(const StorageSummary(
        storageSavedBytes: 0,
        totalPhotosDeleted: 0,
        totalPhotosReviewed: 0,
      )));
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('shows correct progress ratio', (tester) async {
      await tester.pumpWidget(_wrap(const StorageSummary(
        storageSavedBytes: 500000,
        totalPhotosDeleted: 5,
        totalPhotosReviewed: 10,
      )));
      // 5/10 = 50%
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('does not crash when storageSavedBytes is 0', (tester) async {
      await tester.pumpWidget(_wrap(const StorageSummary(
        storageSavedBytes: 0,
        totalPhotosDeleted: 0,
        totalPhotosReviewed: 5,
      )));
      expect(find.textContaining('0 B'), findsOneWidget);
    });
  });
}
