import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/services/weekly_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStat _makeDailyStat({
  required String date,
  int reviewed = 0,
  int deleted = 0,
  int storageSaved = 0,
}) =>
    DailyStat(date: date, reviewed: reviewed, deleted: deleted, storageSaved: storageSaved);

void main() {
  late WeeklyAggregationService service;

  setUp(() => service = WeeklyAggregationService());

  group('compute()', () {
    test('returns empty list when dailyStats is empty', () {
      expect(service.compute([]), isEmpty);
    });

    test('groups 7 consecutive days into one WeeklyStat', () {
      final stats = List.generate(
        7, (i) {
          final dt = DateTime(2024, 1, 15).add(Duration(days: i));
          return _makeDailyStat(date: '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}', reviewed: 1);
        });
      final result = service.compute(stats);
      expect(result.length, 1);
      expect(result.first.weekStart, '2024-01-15');
      expect(result.first.weekEnd, '2024-01-21');
    });

    test('splits stats from two different weeks into two WeeklyStats', () {
      final stats = [
        _makeDailyStat(date: '2024-01-15'),
        _makeDailyStat(date: '2024-01-22'),
      ];
      expect(service.compute(stats).length, 2);
    });

    test('week windows always start on Monday', () {
      // 2024-01-17 is a Wednesday
      final stats = [_makeDailyStat(date: '2024-01-17', reviewed: 3)];
      final result = service.compute(stats);
      expect(result.first.weekStart, '2024-01-15'); // Monday
      expect(result.first.weekEnd, '2024-01-21');   // Sunday
    });

    test('sorts result by weekStart descending', () {
      final stats = [
        _makeDailyStat(date: '2024-01-15'),
        _makeDailyStat(date: '2024-01-22'),
        _makeDailyStat(date: '2024-02-05'),
      ];
      final result = service.compute(stats);
      expect(result[0].weekStart.compareTo(result[1].weekStart), greaterThan(0));
      expect(result[1].weekStart.compareTo(result[2].weekStart), greaterThan(0));
    });

    test('correctly sums totals per window', () {
      final stats = [
        _makeDailyStat(date: '2024-01-15', reviewed: 5, deleted: 3, storageSaved: 1048576),
        _makeDailyStat(date: '2024-01-16', reviewed: 8, deleted: 2, storageSaved: 524288),
      ];
      final result = service.compute(stats);
      expect(result.first.totalReviewed, 13);
      expect(result.first.totalDeleted, 5);
      expect(result.first.storageSaved, 1572864);
    });
  });

  group('getCurrentWeekStats()', () {
    test('returns stat whose window contains today', () {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final key = '${monday.year}-${monday.month.toString().padLeft(2,'0')}-${monday.day.toString().padLeft(2,'0')}';
      final stats = service.compute([_makeDailyStat(date: key, reviewed: 7)]);
      expect(service.getCurrentWeekStats(stats)?.totalReviewed, 7);
    });

    test('returns null when no data for current week', () {
      final stats = [_makeDailyStat(date: '2020-01-06')];
      final result = service.compute(stats);
      expect(service.getCurrentWeekStats(result), isNull);
    });
  });

  group('getPreviousWeekStats()', () {
    test('returns stat whose window contains last week', () {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final monday = lastWeek.subtract(Duration(days: lastWeek.weekday - 1));
      final key = '${monday.year}-${monday.month.toString().padLeft(2,'0')}-${monday.day.toString().padLeft(2,'0')}';
      final stats = service.compute([_makeDailyStat(date: key, reviewed: 4)]);
      expect(service.getPreviousWeekStats(stats)?.totalReviewed, 4);
    });

    test('returns null when no data for last week', () {
      expect(service.getPreviousWeekStats([]), isNull);
    });
  });

  group('computeWeekOverWeekDelta()', () {
    final current = WeeklyStat(weekStart: '2024-01-22', weekEnd: '2024-01-28',
        totalReviewed: 10, totalDeleted: 5, storageSaved: 2000000);
    final previous = WeeklyStat(weekStart: '2024-01-15', weekEnd: '2024-01-21',
        totalReviewed: 7, totalDeleted: 3, storageSaved: 1000000);

    test('positive delta when current > previous', () {
      final delta = service.computeWeekOverWeekDelta(current, previous);
      expect(delta.deletedDelta, 2);
      expect(delta.storageDelta, 1000000);
      expect(delta.reviewedDelta, 3);
    });

    test('negative delta when current < previous', () {
      final delta = service.computeWeekOverWeekDelta(previous, current);
      expect(delta.deletedDelta, -2);
    });

    test('WeekDelta.zero when both inputs are null', () {
      final delta = service.computeWeekOverWeekDelta(null, null);
      expect(delta.deletedDelta, 0);
      expect(delta.storageDelta, 0);
      expect(delta.reviewedDelta, 0);
    });

    test('isImproving true when deletedDelta >= 0', () {
      expect(service.computeWeekOverWeekDelta(current, previous).isImproving, isTrue);
    });

    test('isImproving false when deletedDelta < 0', () {
      expect(service.computeWeekOverWeekDelta(previous, current).isImproving, isFalse);
    });
  });

  group('edge cases', () {
    test('stats spanning a month boundary → correct windows', () {
      // 2024-01-29 (Mon) to 2024-02-04 (Sun)
      final stats = [
        _makeDailyStat(date: '2024-01-29', reviewed: 2),
        _makeDailyStat(date: '2024-02-01', reviewed: 3),
        _makeDailyStat(date: '2024-02-04', reviewed: 1),
      ];
      final result = service.compute(stats);
      expect(result.length, 1);
      expect(result.first.weekStart, '2024-01-29');
      expect(result.first.weekEnd, '2024-02-04');
      expect(result.first.totalReviewed, 6);
    });

    test('stats spanning a year boundary → correct windows', () {
      // 2024-12-30 (Mon) through 2025-01-05 (Sun)
      final stats = [
        _makeDailyStat(date: '2024-12-30', reviewed: 1),
        _makeDailyStat(date: '2025-01-02', reviewed: 2),
      ];
      final result = service.compute(stats);
      expect(result.length, 1);
      expect(result.first.weekStart, '2024-12-30');
      expect(result.first.weekEnd, '2025-01-05');
    });

    test('single DailyStat → one WeeklyStat with matching totals', () {
      final stats = [_makeDailyStat(date: '2024-01-15', reviewed: 9, deleted: 4, storageSaved: 512)];
      final result = service.compute(stats);
      expect(result.length, 1);
      expect(result.first.totalReviewed, 9);
      expect(result.first.totalDeleted, 4);
      expect(result.first.storageSaved, 512);
    });
  });
}
