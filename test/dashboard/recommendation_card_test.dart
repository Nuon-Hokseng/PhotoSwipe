import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/features/dashboard/widgets/recommendation_card.dart';
import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget w) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: w)));

Recommendation _makeRec({
  RecommendationType type = RecommendationType.blur,
  double confidence = 0.80,
}) =>
    Recommendation(
      id: 'r1',
      type: type,
      photoIds: ['p1', 'p2'],
      reason: 'Test reason text',
      confidence: confidence,
      action: RecommendationAction.delete,
    );

void main() {
  group('RecommendationCard', () {
    testWidgets('renders reason text', (tester) async {
      await tester.pumpWidget(_wrap(RecommendationCard(
        recommendation: _makeRec(), photoMap: const {})));
      expect(find.text('Test reason text'), findsOneWidget);
    });

    testWidgets('shows correct accent color for blur type', (tester) async {
      await tester.pumpWidget(_wrap(RecommendationCard(
        recommendation: _makeRec(type: RecommendationType.blur),
        photoMap: const {})));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBlurColor = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == kColorBlurTag;
      });
      expect(hasBlurColor, isTrue);
    });

    testWidgets('shows correct accent color for duplicate type', (tester) async {
      await tester.pumpWidget(_wrap(RecommendationCard(
        recommendation: _makeRec(type: RecommendationType.duplicate),
        photoMap: const {})));
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasDupColor = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == kColorDuplicateTag;
      });
      expect(hasDupColor, isTrue);
    });

    testWidgets('hides accept button when onAccept is null', (tester) async {
      await tester.pumpWidget(_wrap(RecommendationCard(
        recommendation: _makeRec(), photoMap: const {},
        onDismiss: () {})));
      expect(find.text('Clean up'), findsNothing);
    });

    testWidgets('hides dismiss button when onDismiss is null', (tester) async {
      await tester.pumpWidget(_wrap(RecommendationCard(
        recommendation: _makeRec(), photoMap: const {},
        onAccept: () {})));
      expect(find.text('Ignore'), findsNothing);
    });

    testWidgets('calls onAccept when Clean up is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(RecommendationCard(
        recommendation: _makeRec(), photoMap: const {},
        onAccept: () => called = true)));
      await tester.tap(find.text('Clean up'));
      expect(called, isTrue);
    });

    testWidgets('calls onDismiss when Ignore is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(RecommendationCard(
        recommendation: _makeRec(), photoMap: const {},
        onDismiss: () => called = true)));
      await tester.tap(find.text('Ignore'));
      expect(called, isTrue);
    });
  });
}
