import 'package:background_remover/features/dashboard/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  group('StatCard', () {
    testWidgets('renders label and value correctly', (tester) async {
      await tester.pumpWidget(_wrap(const StatCard(
          label: 'Reviewed', value: '42', trend: TrendDirection.neutral)));
      expect(find.text('Reviewed'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows up arrow for TrendDirection.up', (tester) async {
      await tester.pumpWidget(_wrap(const StatCard(
          label: 'L', value: 'V', trend: TrendDirection.up)));
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('shows down arrow for TrendDirection.down', (tester) async {
      await tester.pumpWidget(_wrap(const StatCard(
          label: 'L', value: 'V', trend: TrendDirection.down)));
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('shows dash for TrendDirection.neutral', (tester) async {
      await tester.pumpWidget(_wrap(const StatCard(
          label: 'L', value: 'V', trend: TrendDirection.neutral)));
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('renders unit text when provided', (tester) async {
      await tester.pumpWidget(_wrap(const StatCard(
          label: 'L', value: 'V', trend: TrendDirection.neutral, unit: 'MB freed')));
      expect(find.text('MB freed'), findsOneWidget);
    });

    testWidgets('does not render unit text when null', (tester) async {
      await tester.pumpWidget(_wrap(const StatCard(
          label: 'L', value: 'V', trend: TrendDirection.neutral)));
      expect(find.text('MB freed'), findsNothing);
    });
  });
}
