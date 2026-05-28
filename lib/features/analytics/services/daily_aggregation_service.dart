import 'package:background_remover/features/analytics/analytics_constants.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';

class DailyAggregationService {
  static const _tag = 'DailyAggregationService';

  /// Runs the full daily aggregation pipeline over a list of sessions.
  List<DailyStat> compute(List<Session> sessions) {
    if (sessions.isEmpty) return [];
    final filtered = _filterCompletedSessions(sessions);
    if (filtered.isEmpty) return [];
    final grouped = _groupSessionsByDate(filtered);
    final stats = _buildDailyStats(grouped);
    return _sortByDateDescending(stats);
  }

  /// Filters to sessions where [Session.endedAt] is not null.
  List<Session> _filterCompletedSessions(List<Session> sessions) =>
      sessions.where((s) => s.endedAt != null).toList();

  /// Groups sessions by 'yyyy-MM-dd' date key derived from [Session.startedAt].
  Map<String, List<Session>> _groupSessionsByDate(List<Session> sessions) {
    final map = <String, List<Session>>{};
    for (final s in sessions) {
      if (s.startedAt <= 0) {
        AppLogger.warning(_tag,
            'Skipping session ${s.id}: invalid startedAt=${s.startedAt}');
        continue;
      }
      DateTime dt;
      try {
        dt = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
      } catch (e) {
        AppLogger.error(_tag,
            'Date parse failed for session ${s.id} startedAt=${s.startedAt}: $e');
        continue;
      }
      map.putIfAbsent(_toYmd(dt), () => []).add(s);
    }
    return map;
  }

  /// Reduces each date group into a single [DailyStat], clamping negatives to 0.
  List<DailyStat> _buildDailyStats(Map<String, List<Session>> grouped) =>
      grouped.entries.map((entry) {
        final list = entry.value;
        int pos(int v) => v < 0 ? 0 : v;
        if (list.any((s) => s.reviewed < 0 || s.deleted < 0 || s.storageSaved < 0)) {
          AppLogger.warning(
              _tag, 'Negative values in sessions for ${entry.key} — clamped to 0');
        }
        return DailyStat(
          date: entry.key,
          reviewed: list.fold(0, (sum, s) => sum + pos(s.reviewed)),
          deleted: list.fold(0, (sum, s) => sum + pos(s.deleted)),
          storageSaved: list.fold(0, (sum, s) => sum + pos(s.storageSaved)),
        );
      }).toList();

  /// Sorts [DailyStat] list by date, most recent first.
  List<DailyStat> _sortByDateDescending(List<DailyStat> stats) =>
      (List<DailyStat>.from(stats)..sort((a, b) => b.date.compareTo(a.date)));

  /// Returns daily stats for sessions whose startedAt falls within [from]..[to] inclusive.
  List<DailyStat> computeForRange(
    List<Session> sessions,
    DateTime from,
    DateTime to,
  ) {
    if (from.isAfter(to)) {
      AppLogger.warning(_tag,
          'computeForRange: from=$from is after to=$to — returning empty');
      return [];
    }
    if (sessions.length > kLargeSessionListWarningThreshold) {
      AppLogger.warning(_tag,
          'computeForRange: ${sessions.length} sessions is very large — performance may degrade');
    }
    final fromMs = DateTime(from.year, from.month, from.day).millisecondsSinceEpoch;
    final toMs =
        DateTime(to.year, to.month, to.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    return compute(
        sessions.where((s) => s.startedAt >= fromMs && s.startedAt <= toMs).toList());
  }

  /// Returns the [DailyStat] for the exact [date] string, or null if not found.
  DailyStat? getTotalForDay(List<DailyStat> stats, String date) {
    try {
      return stats.firstWhere((s) => s.date == date);
    } catch (_) {
      return null;
    }
  }

  String _toYmd(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
