import 'package:background_remover/features/analytics/analytics_constants.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/services/daily_aggregation_service.dart';
import 'package:background_remover/features/analytics/services/history_service.dart';
import 'package:background_remover/features/analytics/services/session_service.dart';
import 'package:background_remover/features/analytics/services/weekly_aggregation_service.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/utils/benchmark_utils.dart';

class AnalyticsService {
  AnalyticsService(this._sessionService, this._historyService)
      : _daily = DailyAggregationService(),
        _weekly = WeeklyAggregationService();

  // ignore: unused_field — reserved for session-aware stats in future stages
  final SessionService _sessionService;
  final HistoryService _historyService;
  final DailyAggregationService _daily;
  final WeeklyAggregationService _weekly;

  /// The sole public API — returns a fully computed [AnalyticsStats] snapshot.
  Future<Result<AnalyticsStats, AppError>> getStats() =>
      BenchmarkUtils.measure('getStats()', _getStatsImpl);

  Future<Result<AnalyticsStats, AppError>> _getStatsImpl() async {
    final sessionsResult = await _historyService.getAllSessions();
    if (sessionsResult.isFailure) {
      return Result.failure(AppError.statsUnavailable);
    }
    final sessions = (sessionsResult as Success<List<Session>, AppError>).data;
    final limited = sessions.take(kMaxSessionHistory).toList();
    final dailyStats = _daily.compute(limited);
    final weeklyStats = _weekly.compute(dailyStats);
    return Result.success(AnalyticsStats(
      totalReviewed: limited.fold(0, (s, e) => s + e.reviewed),
      totalKept: limited.fold(0, (s, e) => s + e.kept),
      totalDeleted: limited.fold(0, (s, e) => s + e.deleted),
      storageSaved: limited.fold(0, (s, e) => s + e.storageSaved),
      sessionHistory: limited,
      dailyStats: dailyStats,
      weeklyStats: weeklyStats,
    ));
  }
}
