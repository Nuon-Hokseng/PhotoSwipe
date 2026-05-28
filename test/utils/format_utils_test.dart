import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/utils/image_analysis/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatStorageSize()', () {
    test('500 → "500 B"', () => expect(formatStorageSize(500), '500 B'));
    test('0 → "0 B"', () => expect(formatStorageSize(0), '0 B'));
    test('1536 → "1.5 KB"', () => expect(formatStorageSize(1536), '1.5 KB'));
    test('1048576 → "1.0 MB"', () => expect(formatStorageSize(1048576), '1.0 MB'));
    test('1073741824 → "1.00 GB"', () => expect(formatStorageSize(1073741824), '1.00 GB'));
  });

  group('getWeekRangeLabel()', () {
    test('same month → "15–21 Jan 2024"', () {
      expect(getWeekRangeLabel('2024-01-15', '2024-01-21'), '15–21 Jan 2024');
    });

    test('different months → "28 Jan – 3 Feb 2024"', () {
      expect(getWeekRangeLabel('2024-01-28', '2024-02-03'), '28 Jan – 3 Feb 2024');
    });

    test('year boundary → "30 Dec 2023 – 5 Jan 2024"', () {
      expect(getWeekRangeLabel('2023-12-30', '2024-01-05'), '30 Dec 2023 – 5 Jan 2024');
    });
  });

  group('getDayLabel()', () {
    test('today → "Today"', () {
      final now = DateTime.now();
      final key = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
      expect(getDayLabel(key), 'Today');
    });

    test('yesterday → "Yesterday"', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final key = '${yesterday.year}-${yesterday.month.toString().padLeft(2,'0')}-${yesterday.day.toString().padLeft(2,'0')}';
      expect(getDayLabel(key), 'Yesterday');
    });

    test('older date → "14 Nov"', () {
      expect(getDayLabel('2020-11-14'), '14 Nov');
    });
  });

  group('formatStatDelta()', () {
    test('0 → "—"', () => expect(formatStatDelta(0), '—'));
    test('positive → "+12"', () => expect(formatStatDelta(12), '+12'));
    test('negative → "-5"', () => expect(formatStatDelta(-5), '-5'));
  });

  group('groupByDate()', () {
    test('groups sessions correctly by date string', () {
      final jan15 = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final jan16 = DateTime(2024, 1, 16).millisecondsSinceEpoch;
      final sessions = [
        Session(id: 'a', startedAt: jan15, reviewed: 1, deleted: 0, kept: 1, storageSaved: 0),
        Session(id: 'b', startedAt: jan15 + 3600000, reviewed: 2, deleted: 1, kept: 1, storageSaved: 0),
        Session(id: 'c', startedAt: jan16, reviewed: 3, deleted: 0, kept: 3, storageSaved: 0),
      ];
      final result = groupByDate(sessions, 'yyyy-MM-dd');
      expect(result['2024-01-15']?.length, 2);
      expect(result['2024-01-16']?.length, 1);
    });

    test('returns empty map for empty list', () {
      expect(groupByDate([], 'yyyy-MM-dd'), isEmpty);
    });
  });
}
