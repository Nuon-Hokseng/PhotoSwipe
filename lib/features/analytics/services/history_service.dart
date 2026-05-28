import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/repositories/analytics_repository.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';

class HistoryService {
  HistoryService(this._repo);

  final AnalyticsRepository _repo;

  /// Delegates directly to the repository — returns all sessions.
  Future<Result<List<Session>, AppError>> getAllSessions() =>
      _repo.getAllSessions();

  /// Returns the first [limit] sessions from the full history list.
  Future<Result<List<Session>, AppError>> getRecentSessions(int limit) async {
    final result = await _repo.getAllSessions();
    if (result.isFailure) return Result.failure(AppError.statsUnavailable);
    final sessions = (result as Success<List<Session>, AppError>).data;
    return Result.success(sessions.take(limit).toList());
  }

  /// Sums storageSaved across all sessions and returns total bytes.
  Future<Result<int, AppError>> getTotalStorageSaved() async {
    final result = await _repo.getAllSessions();
    if (result.isFailure) return Result.failure(AppError.statsUnavailable);
    final sessions = (result as Success<List<Session>, AppError>).data;
    return Result.success(
      sessions.fold(0, (sum, s) => sum + s.storageSaved),
    );
  }

  /// Sums deleted counts across all sessions.
  Future<Result<int, AppError>> getTotalPhotosDeleted() async {
    final result = await _repo.getAllSessions();
    if (result.isFailure) return Result.failure(AppError.statsUnavailable);
    final sessions = (result as Success<List<Session>, AppError>).data;
    return Result.success(sessions.fold(0, (sum, s) => sum + s.deleted));
  }

  /// Sums reviewed counts across all sessions.
  Future<Result<int, AppError>> getTotalPhotosReviewed() async {
    final result = await _repo.getAllSessions();
    if (result.isFailure) return Result.failure(AppError.statsUnavailable);
    final sessions = (result as Success<List<Session>, AppError>).data;
    return Result.success(sessions.fold(0, (sum, s) => sum + s.reviewed));
  }
}
