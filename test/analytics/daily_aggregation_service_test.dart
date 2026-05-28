import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/services/daily_aggregation_service.dart';
import 'package:flutter_test/flutter_test.dart';

Session _makeSession({
  String? id,
  int? startedAt,
  int? endedAt,
  int reviewed = 0,
  int deleted = 0,
  int kept = 0,
  int storageSaved = 0,
}) =>
    Session(
      id: id ?? 'test-id',
      startedAt: startedAt ?? DateTime(2024, 1, 15).millisecondsSinceEpoch,
      endedAt: endedAt ?? DateTime(2024, 1, 15, 1).millisecondsSinceEpoch,
      reviewed: reviewed,
      deleted: deleted,
      kept: kept,
      storageSaved: storageSaved,
    );

void main() {
  late DailyAggregationService service;

  setUp(() => service = DailyAggregationService());

  group('compute()', () {
    test('returns empty list when sessions is empty', () {
      expect(service.compute([]), isEmpty);
    });

    test('returns empty list when all sessions have null endedAt', () {
      final sessions = [
        _makeSession(endedAt: null),
        _makeSession(endedAt: null),
      ];
      // ignore: avoid_dynamic_calls
      final sessionsWithNullEnd = sessions.map((s) => Session(
            id: s.id,
            startedAt: s.startedAt,
            endedAt: null,
            reviewed: s.reviewed,
            deleted: s.deleted,
            kept: s.kept,
            storageSaved: s.storageSaved,
          )).toList();
      expect(service.compute(sessionsWithNullEnd), isEmpty);
    });

    test('groups two sessions on the same date into one DailyStat', () {
      final jan15 = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final sessions = [
        _makeSession(startedAt: jan15, reviewed: 3),
        _makeSession(startedAt: jan15 + 3600000, reviewed: 4),
      ];
      final result = service.compute(sessions);
      expect(result.length, 1);
      expect(result.first.date, '2024-01-15');
    });

    test('produces two DailyStat entries for sessions on different dates', () {
      final sessions = [
        _makeSession(startedAt: DateTime(2024, 1, 15).millisecondsSinceEpoch),
        _makeSession(startedAt: DateTime(2024, 1, 16).millisecondsSinceEpoch),
      ];
      expect(service.compute(sessions).length, 2);
    });

    test('sorts result by date descending', () {
      final sessions = [
        _makeSession(startedAt: DateTime(2024, 1, 14).millisecondsSinceEpoch),
        _makeSession(startedAt: DateTime(2024, 1, 16).millisecondsSinceEpoch),
        _makeSession(startedAt: DateTime(2024, 1, 15).millisecondsSinceEpoch),
      ];
      final result = service.compute(sessions);
      expect(result[0].date, '2024-01-16');
      expect(result[1].date, '2024-01-15');
      expect(result[2].date, '2024-01-14');
    });

    test('sums reviewed, deleted, storageSaved correctly across same-day sessions', () {
      final jan15 = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final sessions = [
        _makeSession(startedAt: jan15, reviewed: 5, deleted: 3, storageSaved: 1048576),
        _makeSession(startedAt: jan15 + 3600000, reviewed: 8, deleted: 2, storageSaved: 524288),
      ];
      final result = service.compute(sessions);
      expect(result.first.reviewed, 13);
      expect(result.first.deleted, 5);
      expect(result.first.storageSaved, 1572864);
    });
  });

  group('computeForRange()', () {
    final sessions = [
      _makeSession(id: 'a', startedAt: DateTime(2024, 1, 14).millisecondsSinceEpoch, reviewed: 1),
      _makeSession(id: 'b', startedAt: DateTime(2024, 1, 15).millisecondsSinceEpoch, reviewed: 2),
      _makeSession(id: 'c', startedAt: DateTime(2024, 1, 16).millisecondsSinceEpoch, reviewed: 3),
    ];

    test('returns only sessions within the date range', () {
      final result = service.computeForRange(
        sessions, DateTime(2024, 1, 15), DateTime(2024, 1, 15));
      expect(result.length, 1);
      expect(result.first.date, '2024-01-15');
    });

    test('returns empty list when from is after to', () {
      final result = service.computeForRange(
        sessions, DateTime(2024, 1, 16), DateTime(2024, 1, 14));
      expect(result, isEmpty);
    });

    test('includes sessions on boundary dates inclusive', () {
      final result = service.computeForRange(
        sessions, DateTime(2024, 1, 14), DateTime(2024, 1, 16));
      expect(result.length, 3);
    });
  });

  group('getTotalForDay()', () {
    final stats = [
      DailyStat(date: '2024-01-15', reviewed: 5, deleted: 2, storageSaved: 100),
      DailyStat(date: '2024-01-16', reviewed: 3, deleted: 1, storageSaved: 50),
    ];

    test('returns correct DailyStat for an existing date', () {
      final result = service.getTotalForDay(stats, '2024-01-15');
      expect(result?.reviewed, 5);
    });

    test('returns null for a date with no data', () {
      expect(service.getTotalForDay(stats, '2024-01-20'), isNull);
    });
  });

  group('edge cases', () {
    test('session with all zeros → DailyStat with all zeros', () {
      final result = service.compute([_makeSession()]);
      expect(result.first.reviewed, 0);
      expect(result.first.deleted, 0);
      expect(result.first.storageSaved, 0);
    });

    test('100 sessions on the same date → single DailyStat with correct sums', () {
      final jan15 = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final sessions = List.generate(
        100, (i) => _makeSession(startedAt: jan15 + i * 1000, reviewed: 1, deleted: 1, storageSaved: 1024),
      );
      final result = service.compute(sessions);
      expect(result.length, 1);
      expect(result.first.reviewed, 100);
      expect(result.first.deleted, 100);
      expect(result.first.storageSaved, 102400);
    });

    test('session with invalid startedAt → skipped gracefully', () {
      final sessions = [
        _makeSession(startedAt: 0),
        _makeSession(startedAt: DateTime(2024, 1, 15).millisecondsSinceEpoch, reviewed: 5),
      ];
      final result = service.compute(sessions);
      expect(result.length, 1);
      expect(result.first.reviewed, 5);
    });
  });
}
