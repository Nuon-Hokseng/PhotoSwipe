import 'package:background_remover/features/analytics/analytics_constants.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';

class WeekDelta {
  const WeekDelta({
    required this.deletedDelta,
    required this.storageDelta,
    required this.reviewedDelta,
    required this.isImproving,
  });

  static const zero = WeekDelta(
      deletedDelta: 0, storageDelta: 0, reviewedDelta: 0, isImproving: false);

  final int deletedDelta;
  final int storageDelta;
  final int reviewedDelta;
  final bool isImproving;
}

class WeeklyAggregationService {
  static const _tag = 'WeeklyAggregationService';

  /// Runs the full weekly aggregation pipeline. Truncates to kMaxWeeksHistory.
  List<WeeklyStat> compute(List<DailyStat> dailyStats) {
    if (dailyStats.isEmpty) return [];
    final sorted = _sortByDateAscending(dailyStats);
    final truncated = _truncateToMaxWeeks(sorted);
    final grouped = _groupIntoWeekWindows(truncated);
    return _sortByWeekStartDescending(_buildWeeklyStats(grouped));
  }

  List<DailyStat> _sortByDateAscending(List<DailyStat> stats) =>
      (List<DailyStat>.from(stats)..sort((a, b) => a.date.compareTo(b.date)));

  List<DailyStat> _truncateToMaxWeeks(List<DailyStat> sorted) {
    if (sorted.isEmpty) return sorted;
    try {
      final maxDate = _parseYmd(sorted.last.date);
      final cutoff = _toYmd(maxDate.subtract(Duration(days: kMaxWeeksHistory * 7)));
      final filtered = sorted.where((s) => s.date.compareTo(cutoff) >= 0).toList();
      if (filtered.length < sorted.length) {
        AppLogger.warning(_tag,
            'Data spans > $kMaxWeeksHistory weeks — truncated to most recent data');
      }
      return filtered;
    } catch (e) {
      AppLogger.error(_tag, 'Truncation failed: $e — returning full list');
      return sorted;
    }
  }

  /// Groups each [DailyStat] into its ISO calendar week (Monday-start).
  /// Skips stats with malformed date strings.
  Map<String, List<DailyStat>> _groupIntoWeekWindows(List<DailyStat> sorted) {
    final map = <String, List<DailyStat>>{};
    for (final stat in sorted) {
      DateTime dt;
      try {
        dt = _parseYmd(stat.date);
      } catch (e) {
        AppLogger.error(_tag, 'Malformed date "${stat.date}" — skipped: $e');
        continue;
      }
      final monday = dt.subtract(Duration(days: dt.weekday - 1));
      map.putIfAbsent(_toYmd(monday), () => []).add(stat);
    }
    return map;
  }

  List<WeeklyStat> _buildWeeklyStats(Map<String, List<DailyStat>> grouped) =>
      grouped.entries.where((e) => e.value.isNotEmpty).map((entry) {
        final monday = _parseYmd(entry.key);
        final list = entry.value;
        return WeeklyStat(
          weekStart: entry.key,
          weekEnd: _toYmd(monday.add(const Duration(days: 6))),
          totalReviewed: list.fold(0, (s, d) => s + d.reviewed),
          totalDeleted: list.fold(0, (s, d) => s + d.deleted),
          storageSaved: list.fold(0, (s, d) => s + d.storageSaved),
        );
      }).toList();

  List<WeeklyStat> _sortByWeekStartDescending(List<WeeklyStat> stats) =>
      (List<WeeklyStat>.from(stats)
        ..sort((a, b) => b.weekStart.compareTo(a.weekStart)));

  /// Returns the [WeeklyStat] whose window contains today, or null.
  WeeklyStat? getCurrentWeekStats(List<WeeklyStat> stats) =>
      _findByDate(stats, _todayYmd());

  /// Returns the [WeeklyStat] whose window contains last week, or null.
  WeeklyStat? getPreviousWeekStats(List<WeeklyStat> stats) =>
      _findByDate(stats,
          _toYmd(DateTime.now().subtract(const Duration(days: 7))));

  /// Returns week-over-week change; [WeekDelta.zero] when both are null.
  WeekDelta computeWeekOverWeekDelta(
      WeeklyStat? current, WeeklyStat? previous) {
    if (current == null && previous == null) return WeekDelta.zero;
    final d = (current?.totalDeleted ?? 0) - (previous?.totalDeleted ?? 0);
    return WeekDelta(
      deletedDelta: d,
      storageDelta: (current?.storageSaved ?? 0) - (previous?.storageSaved ?? 0),
      reviewedDelta:
          (current?.totalReviewed ?? 0) - (previous?.totalReviewed ?? 0),
      isImproving: d >= 0,
    );
  }

  WeeklyStat? _findByDate(List<WeeklyStat> stats, String ymd) {
    try {
      return stats.firstWhere(
          (s) => s.weekStart.compareTo(ymd) <= 0 && s.weekEnd.compareTo(ymd) >= 0);
    } catch (_) {
      return null;
    }
  }

  String _todayYmd() => _toYmd(DateTime.now());

  DateTime _parseYmd(String date) {
    final p = date.split('-');
    if (p.length != 3) throw FormatException('Invalid date: $date');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  String _toYmd(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
