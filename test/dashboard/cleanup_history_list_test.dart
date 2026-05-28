import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/dashboard/widgets/cleanup_history_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget w) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: w)));

Session _makeSession(String id) => Session(
  id: id, startedAt: 1700000000000, endedAt: 1700003600000,
  reviewed: 5, deleted: 3, kept: 2, storageSaved: 1048576,
);

void main() {
  group('CleanupHistoryList', () {
    testWidgets('shows empty state when sessions list is empty', (tester) async {
      await tester.pumpWidget(_wrap(
          const CleanupHistoryList(sessions: [])));
      expect(find.text('No cleanup sessions yet'), findsOneWidget);
    });

    testWidgets('renders correct number of items up to maxItems', (tester) async {
      final sessions = List.generate(5, (i) => _makeSession('s$i'));
      await tester.pumpWidget(
          _wrap(CleanupHistoryList(sessions: sessions, maxItems: 3)));
      // 3 items visible, 'See all' row appears
      expect(find.textContaining('reviewed'), findsNWidgets(3));
    });

    testWidgets('shows see-all row when sessions exceed maxItems', (tester) async {
      final sessions = List.generate(5, (i) => _makeSession('s$i'));
      await tester.pumpWidget(
          _wrap(CleanupHistoryList(sessions: sessions, maxItems: 3)));
      expect(find.textContaining('See all 5'), findsOneWidget);
    });

    testWidgets('does not show see-all when sessions <= maxItems', (tester) async {
      final sessions = List.generate(3, (i) => _makeSession('s$i'));
      await tester.pumpWidget(
          _wrap(CleanupHistoryList(sessions: sessions, maxItems: 5)));
      expect(find.textContaining('See all'), findsNothing);
    });
  });
}
